#!/bin/sh

# Initialize Ollama and start the service
init-ollama && exec ./ollama serve
