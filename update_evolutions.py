import json
import urllib.request
import urllib.error
import ssl
import time

POKEDEX_FILE = 'assets/data/pokedex_catalog.json'
USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36'

def get_ssl_context():
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    return ctx

def fetch_json(url):
    print(f"Fetching {url }...")
    req = urllib.request.Request(
        url, 
        data=None, 
        headers={'User-Agent': USER_AGENT}
    )
    try:
        with urllib.request.urlopen(req, context=get_ssl_context()) as response:
            if response.status == 200:
                result = json.loads(response.read().decode())
                time.sleep(0.05) # Rate limit
                return result
    except urllib.error.HTTPError as e:
        print(f"HTTP Error fetching {url}: {e.code}")
    except Exception as e:
        print(f"Error fetching {url}: {e}")
    return None

def format_trigger(details_list):
    if not details_list:
        return None
    
    # Usually the first Detail is sufficient
    d = details_list[0]
    trigger_type = d.get('trigger', {}).get('name')
    
    parts = []
    
    if trigger_type == 'level-up':
        if d.get('min_level'):
            parts.append(f"Level {d['min_level']}")
        if d.get('min_happiness'):
            parts.append("Friendship")
        if d.get('known_move'):
            move = d['known_move']['name'].replace('-', ' ').title()
            parts.append(f"Knows {move}")
        if d.get('time_of_day'):
             parts.append(d['time_of_day'].title())
        if not parts:
            parts.append("Level Up")
            
    elif trigger_type == 'use-item':
        if d.get('item'):
            item = d['item']['name'].replace('-', ' ').title()
            parts.append(item)
        else:
            parts.append("Use Item")
            
    elif trigger_type == 'trade':
        parts.append("Trade")
        if d.get('held_item'):
            item = d['held_item']['name'].replace('-', ' ').title()
            parts.append(f"holding {item}")
            
    else:
        parts.append(trigger_type.replace('-', ' ').title())
        
    return ", ".join(parts)

def extract_chain(chain_node, parent_dex_id=None):
    species_url = chain_node['species']['url']
    name = chain_node['species']['name']
    
    # Extract dex ID from URL
    try:
        dex_id = int(species_url.split('/')[-2])
    except:
        dex_id = 0

    evolution_details = chain_node.get('evolution_details', [])
    trigger_text = format_trigger(evolution_details)

    current_node = {
        'dex': dex_id,
        'name': name,
        'evolves_from_dex': parent_dex_id,
        'trigger': trigger_text
    }
    
    chain_list = [current_node]
    
    for next_node in chain_node.get('evolves_to', []):
        chain_list.extend(extract_chain(next_node, dex_id))
        
    return chain_list

def update_evolutions():
    try:
        with open(POKEDEX_FILE, 'r') as f:
            pokedex = json.load(f)
    except FileNotFoundError:
        print(f"File {POKEDEX_FILE} not found.")
        return

    # Map dex -> entry
    dex_map = {entry['dex']: entry for entry in pokedex}
    processed_chains = set()
    
    # Sort for consistent processing
    sorted_entries = sorted(pokedex, key=lambda x: x['dex'])
    
    updated_count = 0

    for entry in sorted_entries:
        dex_id = entry['dex']
        name = entry['name']
        
        # Optimistic check: if evolutions already exist and have evolves_from_dex, skip
        # Wait, current data doesn't have evolves_from_dex. Force update.
        
        # Get Species Info to find Chain URL
        species_data = fetch_json(f'https://pokeapi.co/api/v2/pokemon-species/{dex_id}/')
        if not species_data:
            print(f"Skipping #{dex_id} {name} due to fetch error.")
            continue
            
        evolution_chain_url = species_data.get('evolution_chain', {}).get('url')
        if not evolution_chain_url:
            print(f"No evolution chain for #{dex_id} {name}.")
            continue
            
        # Optimization: Don't re-fetch shared chains
        chain_id = evolution_chain_url.split('/')[-2]
        if chain_id in processed_chains:
            # We already processed this chain, but we need to assign the result to *this* pokemon
            # However, since we process the whole chain and assign to ALL members in one go, we can skip if ANY member was updated?
            # Actually, let's just create a map of chain_id -> evolution_list and apply it later
            continue
            
        print(f"Processing chain {chain_id} for #{dex_id} {name}...")
        chain_data = fetch_json(evolution_chain_url)
        if not chain_data:
            continue
            
        # Extract full flat list with parent details
        flat_chain = extract_chain(chain_data['chain'])
        
        # Sort by dex ID for tidiness
        flat_chain.sort(key=lambda x: x['dex'])
        
        # Assign this chain to ALL members present in our pokedex
        for evo_node in flat_chain:
            member_dex = evo_node['dex']
            if member_dex in dex_map:
                dex_map[member_dex]['evolutions'] = flat_chain
                updated_count += 1
                
        processed_chains.add(chain_id)

    with open(POKEDEX_FILE, 'w') as f:
        json.dump(pokedex, f, indent=2)
    
    print(f"Done. Updated evolution chains for {updated_count} entries.")

if __name__ == "__main__":
    update_evolutions()
