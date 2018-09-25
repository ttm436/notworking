#!/usr/bin/perl
use warnings;
use strict;

my $ESCAPE = {
	RESET => "\033[0m", #NONE
	KIND => {
		' ' => '',
		Q => "\033[93m", #bright yellow
		A => "\033[94m", #bright blue
		G => "\033[92m", #bright green
		B => "\033[95m", #bright magenta
		S => "\033[91m", #bright red
	},
	TEAM => {
		' ' => '',
		W => "\033[7m",  #invert
		B => "\033[27m", #uninvert
	},
	ID => {
		' ' => ' ', # printing character default
		0 => " ",
		1 => "\xe2\xa0\x84", # 1 braille dot
		2 => "\xe2\xa0\x85", # 2 braille dots
		3 => "\xe2\xa0\x95", # 3 braille dots
	},
};

my $DEBUG = {
	PRINT_TEAM => 0,
	PRINT_KIND => 1,
	PRINT_ID => 1,
};

my $inf_name = $ARGV[0];
open my $inf, "< $inf_name" or die "$!";
chomp (my @lines = <$inf>);
close $inf;

my $first_move = 1;
my ($board, $coord) = ({}, {});
#parse and execute moves
foreach my $line (@lines)
{
	if ($first_move) 
	{
		$line =~ /^(\S\S\S)/;
		$board->{$1}->{x} = 0;
		$board->{$1}->{y} = 0;
		$coord->{0}->{0} = $1;
		$first_move = undef;
		next;
	}
	$line =~ /^(\S\S\S)\s([\\\/-]?\S\S\S?[\\\/-]?)$/;
	my $place_piece = $1;
	my $ref_str = $2;
	my $ref_piece = '';
	my $under_piece = '';
	my ($refx, $refy) = (0,0);
	if ($ref_str =~ /^([\\\/-])(.*)/)
	{
		$ref_piece = $2;
		if ($1 eq '\\')
		{
			$refy --;
		}
		elsif ($1 eq '/')
		{
			$refx --;
			$refy ++;
		}
		elsif ($1 eq '-')
		{
			$refx --;
		}
	}
	elsif ($ref_str =~ /^(.*?)([\\\/-])/)
	{
		$ref_piece = $1;
		if ($2 eq '\\')
		{
			$refy ++;
		}
		elsif ($2 eq '/')
		{
			$refx ++;
			$refy --;
		}
		elsif ($2 eq '-')
		{
			$refx ++;
		}
	}
	else
	{
		$ref_piece = $ref_str;
		$under_piece = $ref_piece;
	}
	my $placex = $board->{$ref_piece}->{x} + $refx;
	my $placey = $board->{$ref_piece}->{y} + $refy;

	#Is piece already placed?
	if ($board->{$place_piece})
	{
		if ($board->{$place_piece}->{under})
		{
			$coord->{ $board->{$place_piece}->{x} }->{ $board->{$place_piece}->{y} } = $board->{$place_piece}->{under};
		}
		else
		{
			delete $coord->{ $board->{$place_piece}->{x} }->{ $board->{$place_piece}->{y} };
		}
	}

	$board->{$place_piece}->{x} = $placex;
	$board->{$place_piece}->{y} = $placey;
	$board->{$place_piece}->{under} = $under_piece;
	$coord->{$placex}->{$placey} = $place_piece;
}

# Construct board tile boundries
my $slashes = {};
my $bars = {};
my $lowx = (sort {$a<=>$b} keys $coord)[0];
my $lowy = (sort {$a<=>$b} (map {keys $_} (values $coord)))[0];
foreach my $x (keys $coord)
{
	foreach my $y (keys $coord->{$x})
	{
		my ($adjx, $adjy) = ($x - $lowx, $y - $lowy);
		$slashes->{$adjy} = $slashes->{$adjy} // 0;
		$slashes->{$adjy+1} = $slashes->{$adjy+1} // 0;
		$bars->{$adjy} = $bars->{$adjy} // 0;

		$slashes->{$adjy} |= (3 << (2*$adjx + $adjy));
		$slashes->{$adjy+1} |= (3 << (2*$adjx + $adjy));
		$bars->{$adjy} |= (5 << (2*$adjx + $adjy));
	}
}

# Print Board
foreach my $y (sort {$a<=>$b} keys $slashes)
{
	my $line = ' ';
	my $x = 0;
	while ($slashes->{$y} != 0)
	{
		$line .= ($slashes->{$y} & 1) ? ( (($y + $x)%2) ? '\\ ' : '/ ' ) : '  ';
		$slashes->{$y} = $slashes->{$y} >> 1;
		$x ++;
	}
	print $line . "\n";
	$line = '';
	$x = 0;
	while ($bars->{$y} // 0 != 0)
	{
		my $coordx = $lowx + ($x - $y - 1 + ($bars->{$y} & 1)) / 2;
		my $coordy = $y + $lowy;
		my $piece = $coord->{$coordx}->{$coordy} // '   ';
		my $team = substr($piece, 0, 1);
		my $kind = substr($piece, 1, 1);
		my $id = substr($piece, 2, 1);
		$line .= ($bars->{$y} & 1) ?
				 ('|' . $ESCAPE->{KIND}->{$kind} . $ESCAPE->{TEAM}->{$team} . ($DEBUG->{PRINT_TEAM} ? $team : ' ')) :
				 (($DEBUG->{PRINT_KIND} ? $kind : ' ') .  ($DEBUG->{PRINT_ID} ? $ESCAPE->{ID}->{$id} : ' ') . $ESCAPE->{RESET});
		$bars->{$y} = $bars->{$y} >> 1;
		$x ++;
	}
	print $line . "\n";
}
