# Epochtalk Server

[![Build Status](https://github.com/epochtalk/epochtalk_server/actions/workflows/main.yml/badge.svg)](https://github.com/epochtalk/epochtalk_server/actions)
[![Documentation](https://img.shields.io/badge/documentation-gray)](https://docs.epochtalk.org/api-reference.html)

Phoenix Framework server for Epochtalk

This project is still under development, see [Port Roadmap](/PortRoadmap.md) for more details.

See [API Reference](https://docs.epochtalk.org/api-reference.html) for API documentation

Please review [Contribution Guidelines](https://github.com/epochtalk/epochtalk_server/blob/main/CONTRIBUTIONS.md) before submitting code

## Getting Started

### Requirements

Postgres
Redis
[epochtalk-vue](https://github.com/epochtalk/epochtalk-vue) (Frontend functionality)

### Installation

Install dependencies with `mix deps.get`

Set up postgres database with `mix ecto.setup`

Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`
