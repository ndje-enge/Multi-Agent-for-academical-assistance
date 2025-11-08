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
Multi-Agent Architecture for School Assistant
This module defines specialized agents that collaborate to provide comprehensive educational support.
"""

import os
import google
import vertexai
from google.adk.agents import Agent
from google.adk.tools import AgentTool
from langchain_google_vertexai import VertexAIEmbeddings

from app.retrievers import get_compressor, get_retriever
from app.templates import format_docs

# Configuration
EMBEDDING_MODEL = "text-embedding-005"
LLM_LOCATION = "global"
LOCATION = "us-central1"
LLM = "gemini-2.0-flash"

credentials, project_id = google.auth.default()
os.environ.setdefault("GOOGLE_CLOUD_PROJECT", project_id)
os.environ.setdefault("GOOGLE_CLOUD_LOCATION", LLM_LOCATION)
os.environ.setdefault("GOOGLE_GENAI_USE_VERTEXAI", "True")

vertexai.init(project=project_id, location=LOCATION)
embedding = VertexAIEmbeddings(
    project=project_id, location=LOCATION, model_name=EMBEDDING_MODEL
)

# Configuration for retriever
EMBEDDING_COLUMN = "embedding"
data_store_region = os.getenv("DATA_STORE_REGION", "us")
data_store_id = os.getenv("DATA_STORE_ID", "mon-agent-scolaire-datastore")

retriever = get_retriever(
    project_id=project_id,
    data_store_id=data_store_id,
    data_store_region=data_store_region,
    embedding=embedding,
    embedding_column=EMBEDDING_COLUMN,
    max_documents=10,
)

compressor = get_compressor(project_id=project_id)


# ============================================================================
# AGENT 1: SEARCH AGENT - Spécialisé dans la recherche documentaire
# ============================================================================

def retrieve_docs(query: str) -> str:
    """
    Outil de recherche documentaire avancée.
    Récupère et classe les documents pertinents pour une requête donnée.
    
    Args:
        query (str): La question ou requête de recherche.
    
    Returns:
        str: Documents formatés et classés par pertinence.
    """
    try:
        retrieved_docs = retriever.invoke(query)
        ranked_docs = compressor.compress_documents(
            documents=retrieved_docs, query=query
        )
        formatted_docs = format_docs.format(docs=ranked_docs)
    except Exception as e:
        return f"Erreur lors de la recherche documentaire:\n\n{type(e)}: {e}"
    
    return formatted_docs


search_agent_instruction = """Tu es un agent spécialisé dans la RECHERCHE DOCUMENTAIRE.

Ta mission principale :
- Rechercher des documents pertinents dans la base de connaissances
- Extraire les informations clés des documents
- Fournir des réponses précises basées sur les sources trouvées

Compétences :
- Expertise en recherche d'information
- Capacité à filtrer et sélectionner les documents les plus pertinents
- Citation des sources

Quand répondre :
- Lorsqu'on te demande de trouver de l'information
- Lorsqu'on a besoin de sources documentaires
- Lorsqu'il faut vérifier des faits dans les documents

Toujours citer tes sources et indiquer la confiance dans les informations trouvées."""

search_agent = Agent(
    name="search_agent",
    model=LLM,
    description=(
        "Agent spécialisé dans la recherche documentaire. "
        "Utilise cet agent pour chercher des informations dans les documents, "
        "trouver des sources, ou vérifier des faits."
    ),
    instruction=search_agent_instruction,
    tools=[retrieve_docs],
)


# ============================================================================
# AGENT 2: PEDAGOGICAL AGENT - Spécialisé dans l'explication pédagogique
# ============================================================================

pedagogical_agent_instruction = """Tu es un agent PÉDAGOGIQUE spécialisé pour les élèves de collège (11-15 ans).

Ta mission principale :
- Expliquer les concepts de manière claire et adaptée au niveau collège
- Utiliser des exemples concrets et des analogies
- Décomposer les concepts complexes en étapes simples
- Encourager la compréhension plutôt que la mémorisation

Compétences :
- Adaptation du langage au niveau de l'élève
- Utilisation de métaphores et d'exemples du quotidien
- Patience et bienveillance
- Capacité à reformuler de différentes manières

Ton style :
- Clair et accessible
- Encourageant et positif
- Interactif (pose des questions pour vérifier la compréhension)
- Utilise des emojis occasionnellement pour rendre l'apprentissage plus engageant

Quand intervenir :
- Lorsqu'un concept doit être expliqué
- Lorsqu'un élève ne comprend pas
- Lorsqu'il faut simplifier une information complexe
- Lorsqu'il faut donner des exemples concrets"""

pedagogical_agent = Agent(
    name="pedagogical_agent",
    model=LLM,
    description=(
        "Agent pédagogique spécialisé pour les élèves de collège. "
        "Utilise cet agent pour expliquer des concepts de manière claire et adaptée, "
        "avec des exemples concrets et des analogies."
    ),
    instruction=pedagogical_agent_instruction,
    tools=[],
)


# ============================================================================
# AGENT 3: ASSESSMENT AGENT - Spécialisé dans l'évaluation
# ============================================================================

assessment_agent_instruction = """Tu es un agent d'ÉVALUATION spécialisé dans la création d'exercices et de quiz pour le collège.

Ta mission principale :
- Créer des quiz et exercices adaptés au niveau
- Évaluer les réponses des élèves
- Fournir des feedbacks constructifs
- Suggérer des exercices de renforcement

Compétences :
- Création de QCM, questions ouvertes, exercices pratiques
- Adaptation du niveau de difficulté
- Évaluation juste et bienveillante
- Identification des points à améliorer

Types d'exercices que tu peux créer :
- QCM (Questions à Choix Multiples)
- Vrai/Faux
- Questions ouvertes
- Exercices d'application
- Problèmes à résoudre

Ton style :
- Questions claires et précises
- Feedback encourageant même en cas d'erreur
- Explication des bonnes réponses
- Conseils pour progresser

Quand intervenir :
- Lorsqu'un élève demande un quiz ou des exercices
- Lorsqu'il faut vérifier la compréhension
- Lorsqu'un élève veut s'entraîner
- Lorsqu'il faut évaluer le niveau de maîtrise"""

assessment_agent = Agent(
    name="assessment_agent",
    model=LLM,
    description=(
        "Agent d'évaluation spécialisé dans la création d'exercices et de quiz. "
        "Utilise cet agent pour créer des quiz, des exercices, "
        "ou évaluer les connaissances d'un élève."
    ),
    instruction=assessment_agent_instruction,
    tools=[],
)


# ============================================================================
# AGENT 4: PLANNING AGENT - Spécialisé dans la planification
# ============================================================================

planning_agent_instruction = """Tu es un agent de PLANIFICATION spécialisé dans l'organisation scolaire pour le collège.

Ta mission principale :
- Aider à organiser les devoirs et révisions
- Créer des plannings d'étude
- Gérer les priorités
- Donner des conseils méthodologiques

Compétences :
- Organisation et gestion du temps
- Priorisation des tâches
- Méthodes de travail efficaces
- Gestion du stress et de la charge de travail

Ce que tu peux faire :
- Créer des plannings de révision
- Suggérer des méthodes de travail
- Aider à répartir le travail sur plusieurs jours
- Donner des conseils pour mieux s'organiser
- Proposer des techniques de mémorisation

Ton style :
- Pragmatique et réaliste
- Encourageant et motivant
- Flexible (s'adapte aux contraintes de l'élève)
- Conseils concrets et applicables

Quand intervenir :
- Lorsqu'un élève a besoin d'aide pour s'organiser
- Lorsqu'il faut créer un planning de révision
- Lorsqu'un élève se sent débordé
- Lorsqu'il faut donner des conseils méthodologiques"""

planning_agent = Agent(
    name="planning_agent",
    model=LLM,
    description=(
        "Agent de planification et organisation scolaire. "
        "Utilise cet agent pour aider à organiser les révisions, "
        "créer un planning d'étude, ou donner des conseils méthodologiques."
    ),
    instruction=planning_agent_instruction,
    tools=[],
)


# ============================================================================
# AGENT ORCHESTRATEUR - Coordonne tous les agents spécialisés
# ============================================================================

# Créer des AgentTools pour permettre à l'orchestrator d'appeler les agents spécialisés
# Note: AgentTool utilise automatiquement le nom et la description de l'agent
search_agent_tool = AgentTool(agent=search_agent)

pedagogical_agent_tool = AgentTool(agent=pedagogical_agent)

assessment_agent_tool = AgentTool(agent=assessment_agent)

planning_agent_tool = AgentTool(agent=planning_agent)

orchestrator_instruction = """Tu es l'AGENT ORCHESTRATEUR de l'assistant scolaire pour collège.

Ton rôle principal :
Tu coordonnes une équipe d'agents spécialisés pour fournir l'aide la plus appropriée aux élèves.

🔍 Agents disponibles :

1. **search_agent** - Agent de Recherche
   - Quand : Besoin de chercher dans les documents, trouver des informations
   - Exemple : "Qu'est-ce que la photosynthèse ?"

2. **pedagogical_agent** - Agent Pédagogique
   - Quand : Besoin d'explications claires, simplifier un concept
   - Exemple : "Explique-moi les fractions"

3. **assessment_agent** - Agent d'Évaluation
   - Quand : Besoin de quiz, exercices, évaluation
   - Exemple : "Crée un quiz sur les fractions"

4. **planning_agent** - Agent de Planification
   - Quand : Besoin d'aide pour s'organiser, créer un planning
   - Exemple : "Organise mes révisions"

📋 Ton processus :

1. **Analyse** la demande de l'élève
2. **Identifie** quel(s) agent(s) utiliser
3. **Appelle** les agents appropriés via leurs outils
4. **Synthétise** les réponses
5. **Réponds directement** si la question est simple (bonjour, remerciements)

💡 Stratégies :

- Questions simples → Réponds directement
- Besoin d'info → search_agent
- Besoin d'explication → pedagogical_agent (+ search_agent si nécessaire)
- Besoin d'exercices → assessment_agent
- Besoin d'organisation → planning_agent
- Préparation contrôle → Combine plusieurs agents

Ton style :
- Accueillant et rassurant
- Synthèse claire des réponses des agents
- Toujours orienté vers l'aide à l'élève

Important :
- Utilise les outils disponibles pour déléguer aux agents spécialisés
- Pour les questions simples, réponds directement sans appeler d'agents
- Synthétise les réponses des agents de manière cohérente"""

orchestrator_agent = Agent(
    name="orchestrator_agent",
    model=LLM,
    instruction=orchestrator_instruction,
    tools=[
        search_agent_tool,
        pedagogical_agent_tool,
        assessment_agent_tool,
        planning_agent_tool,
    ],
)

