import from byllm { Model }

glob llm = Model(model_name="gemini/gemini-2.5-flash", api_key="YOUR-API-KEY-HERE");

node QuoteRequest {
    has topic: str;
    can generate_quote with QuoteWalker entry {
        visitor.data["topic"] = self.topic;
    }
}

walker QuoteWalker {
    has data: dict = {};
    can start with `root entry {
        visit [-->(`?QuoteRequest)];
    }

    """Generate an inspirational quote about the following topic: {topic}

    The quote should be original, positive, and concise."""
    def get_quote(data: dict) -> str by llm();
}

with entry {
    print("INSPIRATIONAL QUOTE GENERATOR");
    print("=" * 40);

    topic = input("Enter a topic for your quote: ");

    root ++> QuoteRequest(topic=topic);

    print("\nGenerating your quote...");
    agent = QuoteWalker() spawn root;

    quote = agent.get_quote(agent.data);

    print("\n" + "=" * 40);
    print(" Your Inspirational Quote:");
    print("=" * 40);
    print(quote);
    print("\nKeep shining!");
}