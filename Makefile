dev:
	toucan generate ./src ./dist --base-url http://localhost:3000/

watch:
	toucan watch ./src ./dist --base-url http://localhost:3000/

serve:
	toucan serve ./dist -p 3000
