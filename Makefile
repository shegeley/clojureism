time-machine = guix time-machine -C lock.scm --

shell-default-args = guile-next guile-ares-rs guile-srfi-125

guile-args = -L src -L tests

nrepl:
	${time-machine} shell ${shell-default-args} -- \
		guile ${guile-args} \
		-c "((@ (ares server) run-nrepl-server) #:port 7888)"

repl:
	${time-machine} shell ${shell-default-args} -- \
		guile ${guile-args}

build:
	guix build -f guix.scm -L guix

install:
	guix install -f guix.scm -L guix

test:
	${time-machine} shell ${shell-default-args} -- \
		guile ${guile-args} -s tests.scm
