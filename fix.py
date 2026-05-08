import os
import glob
import re

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # If it's already using mkMerge or isHM, skip
    if "isHM" in content or "mkMerge" in content:
        return

    # Look for environment.systemPackages
    match = re.search(r'environment\.systemPackages\s*=\s*(?:with pkgs;)?\s*\[(.*?)\];', content, re.DOTALL)
    if not match:
        return

    packages_str = match.group(1).strip()
    
    # We want to replace the whole environment.systemPackages block, 
    # but there might be other things in the file.
    
    # So we'll parse the file carefully. We know the standard structure:
    # { config, pkgs, lib, ... }:
    # {
    #   imports = ...
    #   environment.systemPackages = ...
    #   other stuff
    # }
    
    # Replace the { config, pkgs, lib, ... }: block
    # Actually, we can just replace environment.systemPackages block with the merged block,
    # and add the let block at the top of the body.
    
    # regex to find the start of the body
    body_start_match = re.search(r'\{[^\}]*\}:?\s*\{', content)
    if not body_start_match:
        return
        
    # It's better to just manually edit them to ensure correctness.
