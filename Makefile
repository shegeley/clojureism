nrepl:
	guix shell \
	-L guix \
	-f guix.scm \
	guile \
	guile-ares-rs \
	-L guix \
	-- guile \
	-c "((@ (nrepl server) run-nrepl-server) #:port 7888)"

repl:
	guix shell \
	-L guix \
	-f guix.scm \
	guile \
	guile-ares-rs \
	-L guix \
	-- guile

build:
	guix build -f guix.scm -L guix

install:
	guix install -f guix.scm -L guix

test:
	guix shell \
	-L guix \
	-f guix/packages/srfi/srfi-64-ext.scm \
	-f guix.scm \
	guile \
	--rebuild-cache \
	-- guile \
	-L src \
	-L tests \
	-l test-runner.scm
