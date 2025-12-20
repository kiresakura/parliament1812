import { useState } from 'react';
import { HomeScreen1812 } from './components/HomeScreen1812';
import { WaitingRoom1812 } from './components/WaitingRoom1812';
import { RoleCardReveal1812 } from './components/RoleCardReveal1812';
import { VotingScreen1812 } from './components/VotingScreen1812';

type Screen = 'home' | 'waiting' | 'role' | 'voting';

export default function App() {
  const [currentScreen, setCurrentScreen] = useState<Screen>('home');
  const [roomCode, setRoomCode] = useState('');
  const [playerNickname, setPlayerNickname] = useState('');

  const handleCreateRoom = (nickname: string) => {
    setPlayerNickname(nickname);
    // Generate 6-character room code
    setRoomCode(Math.random().toString(36).substring(2, 8).toUpperCase());
    setCurrentScreen('waiting');
  };

  const handleJoinRoom = (nickname: string, code: string) => {
    setPlayerNickname(nickname);
    setRoomCode(code);
    setCurrentScreen('waiting');
  };

  const handleStartGame = () => {
    setCurrentScreen('role');
  };

  const handleRoleViewed = () => {
    setCurrentScreen('voting');
  };

  const handleVoteComplete = () => {
    // In a real game, this might go to next round or end game screen
    // For now, loop back to voting or show results
    alert('投票完成！遊戲將進入下一回合... / Vote complete! Next round starting...');
    setCurrentScreen('voting');
  };

  const handleBackToHome = () => {
    setCurrentScreen('home');
    setRoomCode('');
    setPlayerNickname('');
  };

  return (
    <>
      {currentScreen === 'home' && (
        <HomeScreen1812 
          onCreateRoom={handleCreateRoom}
          onJoinRoom={handleJoinRoom}
        />
      )}

      {currentScreen === 'waiting' && (
        <WaitingRoom1812 
          roomCode={roomCode}
          onStartGame={handleStartGame}
          onBack={handleBackToHome}
        />
      )}

      {currentScreen === 'role' && (
        <RoleCardReveal1812 
          onContinue={handleRoleViewed}
        />
      )}

      {currentScreen === 'voting' && (
        <VotingScreen1812 
          onVoteComplete={handleVoteComplete}
        />
      )}
    </>
  );
}
