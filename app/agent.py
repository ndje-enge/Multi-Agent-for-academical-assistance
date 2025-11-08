# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
Main agent module - Now using Multi-Agent Architecture
This module exports the orchestrator agent as the root_agent for the application.
"""

# mypy: disable-error-code="arg-type"

# Import the orchestrator agent from the multi-agent architecture
from app.multi_agents import (
    orchestrator_agent,
    search_agent,
    pedagogical_agent,
    assessment_agent,
    planning_agent,
)

# The root_agent is now the orchestrator that coordinates all specialized agents
root_agent = orchestrator_agent

# Export all agents for potential direct access
__all__ = [
    "root_agent",
    "orchestrator_agent",
    "search_agent",
    "pedagogical_agent",
    "assessment_agent",
    "planning_agent",
]
