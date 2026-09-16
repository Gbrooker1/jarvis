"""JARVIS tools: weather (Open-Meteo, no key), web search (DuckDuckGo, no key),
and a browser-control stub the user can extend."""
import logging

import requests
from ddgs import DDGS
from livekit.agents import RunContext, function_tool


@function_tool()
async def get_weather(context: RunContext, city: str) -> str:
    """Get the current weather for a given city. No API key needed."""
    try:
        geo = requests.get(
            "https://geocoding-api.open-meteo.com/v1/search",
            params={"name": city, "count": 1, "format": "json"},
            timeout=15,
        ).json()
        if not geo.get("results"):
            return f"Could not find a place called {city}."
        loc = geo["results"][0]
        lat, lon = loc["latitude"], loc["longitude"]
        name = loc.get("name", city)

        wx = requests.get(
            "https://api.open-meteo.com/v1/forecast",
            params={
                "latitude": lat,
                "longitude": lon,
                "current": "temperature_2m,apparent_temperature,weather_code,"
                           "wind_speed_10m,relative_humidity_2m",
                "temperature_unit": "fahrenheit",
            },
            timeout=15,
        ).json()
        cur = wx.get("current", {})
        temp = cur.get("temperature_2m")
        feels = cur.get("apparent_temperature")
        wind = cur.get("wind_speed_10m")
        humidity = cur.get("relative_humidity_2m")
        result = (
            f"Weather in {name}: {temp}F (feels like {feels}F), "
            f"wind {wind} mph, humidity {humidity}%."
        )
        logging.info(result)
        return result
    except Exception as e:
        logging.error(f"Weather lookup failed for {city}: {e}")
        return f"Sorry, I couldn't get the weather for {city} right now."


@function_tool()
async def search_web(context: RunContext, query: str) -> str:
    """Search the web with DuckDuckGo for current information. No API key needed."""
    try:
        with DDGS() as ddgs:
            results = list(ddgs.text(query, max_results=5))
        if not results:
            return "No search results found."
        lines = [
            f"- {r.get('title', '')}: {r.get('body', '')}"
            for r in results
        ]
        summary = "\n".join(lines)
        logging.info(f"Search for '{query}' returned {len(results)} results")
        return summary
    except Exception as e:
        logging.error(f"Web search failed for '{query}': {e}")
        return "Sorry, the web search failed right now."


@function_tool()
async def browser_action(context: RunContext, action: str, target: str = "") -> str:
    """Stub for browser control on the host machine.

    Extend this to drive a local browser (e.g. Playwright) from voice commands.
    Right now it just reports what it was asked to do.
    """
    logging.info(f"Browser action requested: {action} target={target}")
    return (
        f"Browser control is a stub in this build: received action '{action}' "
        f"for '{target}'. Hook this up to a local Playwright driver to go live."
    )
