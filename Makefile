nrepl:
	guix shell \
	-f srfi-125.scm \
	guile-next \
	guile-ares-rs \
	-- guile \
	-c "((@ (nrepl server) run-nrepl-server) #:port 7888)"

test:
	guix shell \
	-f srfi-125.scm \
	-f srfi-64-ext.scm \
	guile \
	--rebuild-cache \
	-- guile \
	-L src \
	-L tests \
	-l test-runner.scm
