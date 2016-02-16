

all:

openzwaveVersion=1.4.1
openzwave-${openzwaveVersion}.tar.gz:
	wget http://old.openzwave.com/downloads/${@}

openzwave-${openzwaveVersion}:openzwave-${openzwaveVersion}.tar.gz
	tar -xzf ${<}
openzwave-${openzwaveVersion}/libopenzwave.a:openzwave-${openzwaveVersion}
	${MAKE} -C ${<}
	
all:openzwave-${openzwaveVersion}/libopenzwave.a
	gprbuild -p -P ada_open_zwave.gpr

clean:
	rm -rf .obj lib openzwave-${openzwaveVersion}*

