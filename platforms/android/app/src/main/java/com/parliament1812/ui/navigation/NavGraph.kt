package com.parliament1812.ui.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.parliament1812.nfc.NFCManager
import com.parliament1812.ui.screens.*

sealed class Screen(val route: String) {
    object Home : Screen("home")

    object WaitingRoom : Screen("waiting_room/{roomCode}/{isHost}") {
        fun createRoute(roomCode: String, isHost: Boolean) =
            "waiting_room/$roomCode/$isHost"
    }

    object NFCScan : Screen("nfc_scan/{roomCode}/{playerId}") {
        fun createRoute(roomCode: String, playerId: String) =
            "nfc_scan/$roomCode/$playerId"
    }

    object RoleCard : Screen("role_card/{roleType}/{roleIndex}") {
        fun createRoute(roleType: String, roleIndex: Int) =
            "role_card/$roleType/$roleIndex"
    }

    object Game : Screen("game/{roomCode}/{playerId}/{isHost}") {
        fun createRoute(roomCode: String, playerId: String, isHost: Boolean) =
            "game/$roomCode/$playerId/$isHost"
    }

    object Message : Screen("message/{roomCode}/{playerId}") {
        fun createRoute(roomCode: String, playerId: String) =
            "message/$roomCode/$playerId"
    }

    object Vote : Screen("vote/{roomCode}/{playerId}/{voteRound}") {
        fun createRoute(roomCode: String, playerId: String, voteRound: Int) =
            "vote/$roomCode/$playerId/$voteRound"
    }

    object HostPanel : Screen("host_panel/{roomCode}/{playerId}") {
        fun createRoute(roomCode: String, playerId: String) =
            "host_panel/$roomCode/$playerId"
    }

    object Result : Screen("result/{roomCode}") {
        fun createRoute(roomCode: String) = "result/$roomCode"
    }
}

@Composable
fun NavGraph(
    nfcManager: NFCManager,
    navController: NavHostController = rememberNavController()
) {
    // Store room state for passing between screens
    val navigationState = remember { NavigationState() }

    NavHost(
        navController = navController,
        startDestination = Screen.Home.route
    ) {
        // Home Screen
        composable(Screen.Home.route) {
            HomeScreen(
                onNavigateToWaitingRoom = { roomCode, isHost, playerId ->
                    navigationState.roomCode = roomCode
                    navigationState.isHost = isHost
                    navigationState.playerId = playerId
                    navController.navigate(Screen.WaitingRoom.createRoute(roomCode, isHost))
                }
            )
        }

        // Waiting Room Screen
        composable(
            route = Screen.WaitingRoom.route,
            arguments = listOf(
                navArgument("roomCode") { type = NavType.StringType },
                navArgument("isHost") { type = NavType.BoolType }
            )
        ) { backStackEntry ->
            val roomCode = backStackEntry.arguments?.getString("roomCode") ?: ""
            val isHost = backStackEntry.arguments?.getBoolean("isHost") ?: false

            WaitingRoomScreen(
                roomCode = roomCode,
                isHost = isHost,
                onNavigateToNFCScan = {
                    val playerId = navigationState.playerId ?: "temp-player-id"
                    navController.navigate(Screen.NFCScan.createRoute(roomCode, playerId))
                },
                onNavigateToGame = {
                    val playerId = navigationState.playerId ?: ""
                    navController.navigate(Screen.Game.createRoute(roomCode, playerId, isHost)) {
                        popUpTo(Screen.WaitingRoom.route) { inclusive = true }
                    }
                },
                onNavigateBack = {
                    navController.popBackStack(Screen.Home.route, false)
                }
            )
        }

        // NFC Scan Screen
        composable(
            route = Screen.NFCScan.route,
            arguments = listOf(
                navArgument("roomCode") { type = NavType.StringType },
                navArgument("playerId") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val roomCode = backStackEntry.arguments?.getString("roomCode") ?: ""
            val playerId = backStackEntry.arguments?.getString("playerId") ?: ""

            NFCScanScreen(
                roomCode = roomCode,
                playerId = playerId,
                nfcManager = nfcManager,
                onRoleAssigned = { roleType, roleIndex ->
                    navController.navigate(Screen.RoleCard.createRoute(roleType, roleIndex)) {
                        popUpTo(Screen.WaitingRoom.route) { inclusive = false }
                    }
                },
                onNavigateBack = {
                    navController.popBackStack()
                }
            )
        }

        // Role Card Screen
        composable(
            route = Screen.RoleCard.route,
            arguments = listOf(
                navArgument("roleType") { type = NavType.StringType },
                navArgument("roleIndex") { type = NavType.IntType }
            )
        ) { backStackEntry ->
            val roleType = backStackEntry.arguments?.getString("roleType") ?: ""
            val roleIndex = backStackEntry.arguments?.getInt("roleIndex") ?: 0

            RoleCardScreen(
                roleType = roleType,
                roleIndex = roleIndex,
                onContinue = {
                    val roomCode = navigationState.roomCode ?: ""
                    navController.navigate(Screen.WaitingRoom.createRoute(roomCode, navigationState.isHost)) {
                        popUpTo(Screen.Home.route) { inclusive = false }
                    }
                }
            )
        }

        // Game Screen
        composable(
            route = Screen.Game.route,
            arguments = listOf(
                navArgument("roomCode") { type = NavType.StringType },
                navArgument("playerId") { type = NavType.StringType },
                navArgument("isHost") { type = NavType.BoolType }
            )
        ) { backStackEntry ->
            val roomCode = backStackEntry.arguments?.getString("roomCode") ?: ""
            val playerId = backStackEntry.arguments?.getString("playerId") ?: ""
            val isHost = backStackEntry.arguments?.getBoolean("isHost") ?: false

            GameScreen(
                roomCode = roomCode,
                playerId = playerId,
                isHost = isHost,
                onNavigateToMessages = {
                    navController.navigate(Screen.Message.createRoute(roomCode, playerId))
                },
                onNavigateToVote = { voteRound ->
                    navController.navigate(Screen.Vote.createRoute(roomCode, playerId, voteRound))
                },
                onNavigateToHostPanel = {
                    navController.navigate(Screen.HostPanel.createRoute(roomCode, playerId))
                },
                onNavigateToResult = {
                    navController.navigate(Screen.Result.createRoute(roomCode)) {
                        popUpTo(Screen.Game.route) { inclusive = true }
                    }
                }
            )
        }

        // Message Screen
        composable(
            route = Screen.Message.route,
            arguments = listOf(
                navArgument("roomCode") { type = NavType.StringType },
                navArgument("playerId") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val roomCode = backStackEntry.arguments?.getString("roomCode") ?: ""
            val playerId = backStackEntry.arguments?.getString("playerId") ?: ""

            MessageScreen(
                roomCode = roomCode,
                playerId = playerId,
                onNavigateBack = {
                    navController.popBackStack()
                }
            )
        }

        // Vote Screen
        composable(
            route = Screen.Vote.route,
            arguments = listOf(
                navArgument("roomCode") { type = NavType.StringType },
                navArgument("playerId") { type = NavType.StringType },
                navArgument("voteRound") { type = NavType.IntType }
            )
        ) { backStackEntry ->
            val roomCode = backStackEntry.arguments?.getString("roomCode") ?: ""
            val playerId = backStackEntry.arguments?.getString("playerId") ?: ""
            val voteRound = backStackEntry.arguments?.getInt("voteRound") ?: 1

            VoteScreen(
                roomCode = roomCode,
                playerId = playerId,
                voteRound = voteRound,
                onNavigateBack = {
                    navController.popBackStack()
                },
                onVoteComplete = {
                    navController.popBackStack()
                }
            )
        }

        // Host Panel Screen
        composable(
            route = Screen.HostPanel.route,
            arguments = listOf(
                navArgument("roomCode") { type = NavType.StringType },
                navArgument("playerId") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val roomCode = backStackEntry.arguments?.getString("roomCode") ?: ""
            val playerId = backStackEntry.arguments?.getString("playerId") ?: ""

            HostPanelScreen(
                roomCode = roomCode,
                playerId = playerId,
                onNavigateBack = {
                    navController.popBackStack()
                }
            )
        }

        // Result Screen
        composable(
            route = Screen.Result.route,
            arguments = listOf(
                navArgument("roomCode") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val roomCode = backStackEntry.arguments?.getString("roomCode") ?: ""

            ResultScreen(
                roomCode = roomCode,
                onNavigateBack = {
                    navController.popBackStack()
                },
                onExitGame = {
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.Home.route) { inclusive = true }
                    }
                }
            )
        }
    }
}

// Simple state holder for navigation
class NavigationState {
    var roomCode: String? = null
    var isHost: Boolean = false
    var playerId: String? = null
}
