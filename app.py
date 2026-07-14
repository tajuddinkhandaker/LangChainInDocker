# Simple Python application using LangChain
from langchain_core.messages import HumanMessage

print("Hello from Python application running in Docker!")
print("Demonstrating LangChain usage.")
# Example usage of HumanMessage
msg = HumanMessage(content="Hello LangChain!")
print(f"Created message: {msg}")