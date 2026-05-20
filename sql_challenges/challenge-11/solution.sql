-- ## 1
from sqlalchemy import (
    create_engine, Column, Integer, String,
    Text, ForeignKey, DateTime, func
)
from sqlalchemy.orm import declarative_base, relationship, Session

Base = declarative_base()

class Team(Base):
    __tablename__ = "teams"
    id          = Column(Integer, primary_key=True)
    name        = Column(String(50), nullable=False, unique=True)
    description = Column(String(200))
    created_at  = Column(DateTime, server_default=func.current_timestamp())
    users = relationship("User", back_populates="team")

    def __repr__(self):
        return f"<Team(id={self.id}, name='{self.name}')>"

class User(Base):
    __tablename__ = "users"
    id         = Column(Integer, primary_key=True)
    username   = Column(String(50), nullable=False, unique=True)
    email      = Column(String(100), nullable=False)
    full_name  = Column(String(100))
    team_id    = Column(Integer, ForeignKey("teams.id"))
    created_at = Column(DateTime, server_default=func.current_timestamp())
    team  = relationship("Team", back_populates="users")
    tasks = relationship("Task", back_populates="assignee")
    comments = relationship("Comment", back_populates="user_id")
    def __repr__(self):
        return f"<User(id={self.id}, username='{self.username}')>"

class Task(Base):
    __tablename__ = "tasks"
    id           = Column(Integer, primary_key=True)
    title        = Column(String(200), nullable=False)
    description  = Column(String(1000))
    status       = Column(String(20), default="open")
    assigned_to  = Column(Integer, ForeignKey("users.id"))
    created_at   = Column(DateTime, server_default=func.current_timestamp())
    updated_at   = Column(DateTime, onupdate=func.current_timestamp())
    assignee = relationship("User", back_populates="tasks")
    comments = relationship("Comment", back_populates="task_id")

class Comment(Base):
    __tablename__ = "comments"
    id           = Column(Integer, primary_key=True)
    content      = Column(String(200), nullable=False)
    task_id      = Column(Integer, ForeignKey("tasks.id"))
    user_id      = Column(Integer, ForeignKey("users.id"))
    created_at   = Column(DateTime, server_default=func.current_timestamp())

    def __repr__(self):
        return f"<Task(id={self.id}, title='{self.title}', status='{self.status}')>"

print("✅ Models defined: Team, User, Task")
--
--1. What relationships should `Comment` have?
-- It should not have any relationship, only FK, as a comment does not have multiple tasks or users
--2. Should `Task` have a `comments` relationship?
-- Yes it should, as you probably want to know  all the comments for a task
--3. What should happen to comments when a task is deleted?
--The comment related to that task should be deleted

-- ## 2
import os
from alembic.config import Config
from alembic import command

# Create a minimal alembic.ini in memory
alembic_cfg = Config()
alembic_cfg.set_main_option('script_location', '/content/alembic')
alembic_cfg.set_main_option('sqlalchemy.url', 'oracle+oracledb://:@')

# Initialize the migration directory
!mkdir -p /content/alembic/versions

# Write a minimal env.py
env_py = '''
from logging.config import fileConfig
from sqlalchemy import engine_from_config
from alembic import context

# This is the Alembic Config object
config = context.config

# Add your model's MetaData object here for 'autogenerate' support
from __main__ import Base
target_metadata = Base.metadata

def run_migrations_offline():
    url = config.get_main_option('sqlalchemy.url')
    context.configure(url=url, target_metadata=target_metadata, literal_binds=True)
    with context.begin_transaction():
        context.run_migrations()

def run_migrations_online():
    connectable = engine_from_config(
        config.get_section(config.config_ini_section),
        prefix='sqlalchemy.',
        connect_args={'user': "''' + USERNAME + '''", 'password': "''' + PASSWORD + '''", 'dsn': "''' + DSN + '''"}
    )
    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)
        with context.begin_transaction():
            context.run_migrations()

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
'''

with open('/content/alembic/env.py', 'w') as f:
    f.write(env_py)

# Write a minimal script.py.mako
script_template = '''"""${message}

Revision ID: ${up_revision}
Revises: ${down_revision | comma,n}
Create Date: ${create_date}
"""

from alembic import op
import sqlalchemy as sa
${imports if imports else ""}

# revision identifiers, used by Alembic.
revision = ${repr(up_revision)}
down_revision = ${repr(down_revision)}
branch_labels = ${repr(branch_labels)}
depends_on = ${repr(depends_on)}

def upgrade():
${upgrades if upgrades else "    pass"}

def downgrade():
${downgrades if downgrades else "    pass"}
with open('/content/alembic/script.py.mako', 'w') as f:
    f.write(script_template)

print('✅ Alembic initialized in /content/alembic/')

# Generate migration from models vs current database state
command.revision(alembic_cfg, autogenerate=True, message='Initial schema')

# Show what was generated
import glob
migration_files = sorted(glob.glob('/content/alembic/versions.py'))
print('Generated migrations:')
for f in migration_files:
    print(f'  {f}')

latest = migration_files[0]
with open(latest) as f:
    content = f.read()

print(content)

command.upgrade(alembic_cfg, 'head')
print('✅ Migration applied! Tables created.')

-- ##  Questions 2
-- 1.  What does `upgrade()` do?
--  It updates to the newest version 
-- 2. What does `downgrade()` do?
--  It makes a "rollback" and gets you to an older version
-- 3. What happens if you downgrade this migration?
-- It will go back as it was originally

-- #3
from sqlalchemy import create_engine
from sqlalchemy.orm import Session

# Re-using the existing database connection details
# (USERNAME, PASSWORD, DSN are available from previous cells)
engine = create_engine(
    "oracle+oracledb://:@",
    connect_args={
        "user": USERNAME,
        "password": PASSWORD,
        "dsn": DSN
    }
)

with Session(engine) as session:
    # 1. Create a team called "DevOps"
    devops_team = session.query(Team).filter_by(name="DevOps").first()
    if not devops_team:
        session.add(devops_team)        devops_team = Team(name="DevOps", description="Team responsible for operations and development.")

        session.commit()
        print(f"✅ Created team: {devops_team.name}")
    else:
        print(f"ℹ️ Team '{devops_team.name}' already exists.")

    # 2. Create a user "diana_ops"
    diana_ops = session.query(User).filter_by(username="diana_ops").first()
    if not diana_ops:
        diana_ops = User(username="diana_ops", email="diana.ops@example.com", full_name="Diana Ops", team=devops_team)
        session.add(diana_ops)
        session.commit()
        print(f"✅ Created user: {diana_ops.username} in {devops_team.name}")
    else:
        # Ensure user is part of DevOps team if already exists
        if diana_ops.team_id != devops_team.id:
            diana_ops.team = devops_team
            session.commit()
            print(f"ℹ️ User '{diana_ops.username}' already exists, assigned to '{devops_team.name}'.")
        else:
            print(f"ℹ️ User '{diana_ops.username}' already exists and is in '{devops_team.name}'.")

    # 3. Create 3 tasks with different priorities (using title for priority indication)
    tasks_to_add = [
        Task(title="Setup CI/CD pipeline (High Priority)", description="Automate deployment process.", assignee=diana_ops),
        Task(title="Monitor production servers (Medium Priority)", description="Regular health checks.", assignee=diana_ops),
        Task(title="Document API endpoints (Low Priority)", description="Create comprehensive API documentation.", assignee=diana_ops)
    ]

    for task_data in tasks_to_add:
        existing_task = session.query(Task).filter_by(title=task_data.title).first()
        if not existing_task:
            session.add(task_data)
            print(f"✅ Created task: {task_data.title}")
        else:
            print(f"ℹ️ Task '{task_data.title}' already exists.")
    session.commit()

    # 4. Prints task count
    all_tasks = session.query(Task).all()
    print(f"\nTotal tasks currently in the system: {len(all_tasks)}")

    # 5. Closes one task (e.g., 'Setup CI/CD pipeline')
    task_to_close = session.query(Task).filter_by(title="Setup CI/CD pipeline (High Priority)").first()
    if task_to_close and task_to_close.status != "closed":
        task_to_close.status = "closed"
        session.commit()
        print(f"\n✅ Closed task: '{task_to_close.title}' (ID: {task_to_close.id})")
    elif task_to_close and task_to_close.status == "closed":
        print(f"\nℹ️ Task '{task_to_close.title}' is already closed.")
    else:
        print(f"\n⚠️ Task 'Setup CI/CD pipeline (High Priority)' not found to close.")

    # 6. Deletes the lowest priority task (e.g., 'Document API endpoints')
    task_to_delete = session.query(Task).filter_by(title="Document API endpoints (Low Priority)").first()
    if task_to_delete:
        session.delete(task_to_delete)
        session.commit()
        print(f"\n✅ Deleted task: '{task_to_delete.title}' (ID: {task_to_delete.id})")
    else:
        print(f"\n⚠️ Task 'Document API endpoints (Low Priority)' not found to delete.")

    # Print updated task count
    all_tasks_after_delete = session.query(Task).all()
    print(f"\nTotal tasks after deletion: {len(all_tasks_after_delete)}")

-- #4
command.downgrade(alembic_cfg, "-1")
print('✅ Migration rolled back by one step.')

--1. What happens to the column?
-- The column will be dropped from the table
--2. What happens to the data?
-- 

-- #5
--1. Why use ORM instead of raw SQL? 
-- ORM allows you to interact with a database using object-oriented code, making it more readable, 
-- maintainable, and less error-prone than  SQL. 
--2. Why use migrations? 
-- They allow for easy updates or rollback of DB versions.
--3. When would you rollback? 
-- You would rollback a migration if it introduced errors, bugs,
-- or if you need to revert the database schema to a previous stable state.
--4. Difference between add() and commit()? 
-- add() stages objects for persistence within a session.
-- commit() then writes all staged changes to the database.
--5. Why are relationships useful? 
-- Relationships in ORM allow us to model connections between tables directly in code, 
-- simplifying data access and navigation between related objects while coding.