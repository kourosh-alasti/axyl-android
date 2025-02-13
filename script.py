import requests
from bs4 import BeautifulSoup
import csv


def scrape_links(url, output_file):
    try:
        res = requests.get(url)

        # Throw error on bad requests
        res.raise_for_status()

        soup = BeautifulSoup(res.text, 'html.parser')
        links = [a['href'] for a in soup.find_all(
            'a', class_='RepoList-item') if 'href' in a.attrs]

        if not links:
            print("No links found with the specified class.")
            return

        with open(output_file, 'w', newline='', encoding='utf-8') as file:
            writer = csv.writer(file)
            writer.writerow(["Links"])
            writer.writerows([[link] for link in links])

        print(f"Successfully save {len(links)} links to {output_file}")
    except requests.RequestException as e:
        print(f"Request Error: {e}")
    except Exception as e:
        print(f"An error occured: {e}")


if __name__ == "__main__":
    url = "https://android.googlesource.com/"
    output_file = "links.csv"
    scrape_links(url, output_file)
