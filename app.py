# Simple Python application using LangChain
from dotenv import load_dotenv
from langchain_core.messages import HumanMessage


def main() -> None:
    load_dotenv()

    print("Hello from Python application running in Docker!")
    print("Demonstrating LangChain usage.")
    # Example usage of HumanMessage
    msg = HumanMessage(content="Hello LangChain!")
    print(f"Created message: {msg}")


if __name__ == "__main__":
    main()