# list available recipes - you are running this!
list:
	@just -l

# update a flake attribute
update attribute branch="":
	nix-update --flake {{ if branch != "" { "--version branch=" + branch } else { "" } }} {{attribute}}
