from reverz import app


def main():
    app.run(debug=False, host="0.0.0.0")


# Checks if the run.py file has executed directly and not imported
if __name__ == "__main__":
    main()
