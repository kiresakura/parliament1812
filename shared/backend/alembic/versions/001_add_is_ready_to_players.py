"""add is_ready to players

Revision ID: 001
Revises:
Create Date: 2024-12-21

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '001'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """新增 is_ready 欄位到 players 表"""
    op.add_column('players', sa.Column('is_ready', sa.Boolean(), nullable=False, server_default='false'))


def downgrade() -> None:
    """移除 is_ready 欄位"""
    op.drop_column('players', 'is_ready')
