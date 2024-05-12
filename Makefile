nrepl:
	guix shell \
	guile-next \
	guile-ares-rs \
	-- guile \
	-e "((@ (nrepl server) run-nrepl-server) #:port 7888)"

test:
	guix shell \
	-f srfi-64-ext.scm \
	guile-next \
	--rebuild-cache \
	-- guile \
	-L src \
	-L tests \
	-l test-runner.scm
