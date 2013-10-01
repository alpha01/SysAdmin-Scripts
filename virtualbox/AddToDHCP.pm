package AddToDHCP;

sub new {
	my $self = {
	_name => undef,
	_hardware => undef,
	_dhcp => undef,
	};

	bless $self, 'AddToDHCP';
	return $self;
}

sub name {
	my ( $self, $name ) = @_;
	$self->{_name} = $name if defined($name);
	return $self->{_name};
}

sub hardware {
	my ( $self, $hardware ) = @_;
	$self->{_hardware} = $hardware if defined($hardware);
	return $self->{_hardware};
}

sub dhcp {
	my ( $self, $dhcp ) = @_;
	$self->{_dhcp} = $dhcp if defined($dhcp);
	return $self->{_dhcp};
}


sub add_to_dhcp {
	my ($self) = @_;
	print "\n\n\nAdding machine: " . $self->name . ' to DHCP Server: ' . $self->dhcp . "\n";
	system('ssh root@' . $self->dhcp . ' "perl add_to_dhcpd.pl --name ' . $self->name . ' --hardware ' . $self->hardware . '"');
}


1;
