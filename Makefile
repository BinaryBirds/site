dev:
	toucan generate ./src ./docs --base-url http://localhost:3000/

dist:
	toucan generate ./src ./docs

watch:
	toucan watch ./src ./docs --base-url http://localhost:3000/

serve:
	toucan serve ./docs -p 3000
