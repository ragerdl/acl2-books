# certlib.pl - Library routines for cert.pl, critpath.pl, etc.
# Copyright 2008-2009 by Sol Swords 
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 675 Mass
# Ave, Cambridge, MA 02139, USA.
#
# NOTE.  This file is not part of the standard ACL2 books build process; it is
# part of an experimental build system that is not yet intended, for example,
# to be capable of running the whole regression.  The ACL2 developers do not
# maintain this file.  Please contact Sol Swords <sswords@cs.utexas.edu> with
# any questions/comments.


use strict;
use warnings;
use File::Basename;
use File::Spec;
use Cwd;
use Cwd 'abs_path';


sub human_time {

# human_time(secs,shortp) returns a string describing the time taken in a
# human-friendly format, e.g., 5.6 minutes, 10.3 hours, etc.  If shortp is
# given, then we use, e.g., "min" instead of "minutes."

    my $secs = shift;
    my $shortp = shift;

    if (!$secs) {
	return "???";
    }

    if ($secs < 60) {
	return sprintf("%.1f %s", $secs, $shortp ? "sec" : "seconds");
    }

    if ($secs < 60 * 60) {
	return sprintf("%.1f %s", ($secs / 60.0), $shortp ? "min" : "minutes");
    }

    return sprintf("%.2f %s", ($secs / (60 * 60)), $shortp ? "hr" : "hours");
}




sub rel_path {
# Composes two paths together.  Basically just builds "$base/$path"
# but handles the special cases where $base is empty or $path is
# absolute.
    my $base = shift;
    my $path = shift;
    if (substr($path,0,1) eq "/" || !$base) {
	return $path;
    } else {
	return "$base/$path";
    }
}

sub rec_readlink {
    my $path = shift;
    while (-l $path) {
	$path = readlink $path;
    }
    return $path;
}


sub abs_canonical_path {
    my $path = shift;
    my $abspath = File::Spec->rel2abs(rec_readlink($path));
    my ($vol, $dir, $file) = File::Spec->splitpath($abspath);
    my $absdir = abs_path($dir);
    if ($absdir) {
	return File::Spec->catpath($vol, $absdir, $file);
    } else {
	print "Warning: canonical_path: Directory not found: " . $dir . "\n";
	return 0;
    }
}

my $BASE_PATH = abs_canonical_path(".");


sub canonical_path {
    my $abs_path = abs_canonical_path(shift);
    if ($BASE_PATH) {
	my $relpath =  File::Spec->abs2rel($abs_path, $BASE_PATH);
	return $relpath ? $relpath : ".";
    } else {
	return $abs_path;
    }
}

sub which {
    my $name = shift;
    # test to see if this is just a filename with no directory -- is this correct?
    if (basename($name) eq $name) {
	foreach my $dir (split(":", $ENV{"PATH"})) {
	    my $file = rel_path($dir, $name);
	    if ((! -d $file) && -x $file) {
		return abs_canonical_path($file);
	    }
	}
    } elsif ((! -d $name) && -x $name) {
	return abs_canonical_path($name);
    }
    return 0;
}
	




sub short_cert_name {

# Given a path to some ACL2 book, e.g., foo/bar/baz/blah.cert, we produce 
# a shortened version of the name, e.g., "baz/blah.cert".  Usually this is 
# enough to identify the book, and keeps the noise of the path down to a 
# minimum.

    my $certfile = shift;
    my $short = shift;

    if ($short == -1) {
	return $certfile;
    }
    
    my $pos = length($certfile)+1;

    while ($short > -1) {
	$pos = rindex($certfile, "/", $pos-1);
	if ($pos == -1) {
	    return $certfile;
	}
	$short = $short-1;
    }
    return substr($certfile, $pos+1);

}


sub get_cert_time {

# Given a .cert file, gets the total user + system time recorded in the
# corresponding .time file.  If not found, prints a warning and returns 0.
# Given an .acl2x file, gets the time recorded in the corresponding
# .acl2x.time file.

    my $path = shift;
    my $warnings = shift;

    $path =~ s/\.cert$/\.time/;
    $path =~ s/\.acl2x$/\.acl2x\.time/;
    
    if (open (my $timefile, "<", $path)) {
	while (my $the_line = <$timefile>) {
	    my $regexp = "^([0-9]*\\.[0-9]*)user ([0-9]*\\.[0-9]*)system";
	    my @res = $the_line =~ m/$regexp/;
	    if (@res) {
		close $timefile;
		return 0.0 + $res[0] + $res[1];
	    }
	}
	push(@$warnings, "Corrupt timings in $path\n");
	close $timefile;
	return 0;
    } else {
	push(@$warnings, "Could not open $path: $!\n");
	return 0;
    }
}


sub read_costs {
    my $deps = shift;
    my $basecosts = shift;
    my $warnings = shift;

    foreach my $certfile (keys %{$deps}) {
	if ($certfile =~ /\.(cert|acl2x)$/) {
	    my $cost = get_cert_time($certfile, $warnings);
	    $basecosts->{$certfile} = $cost;
	}
    }
}

sub find_most_expensive {
    my $files = shift;
    my $costs = shift;

    my $most_expensive_file_total = 0;
    my $most_expensive_file = 0;

    foreach my $file (@{$files}) {
	if ($file =~ /\.(cert|acl2x)$/) {

	    my $file_costs = $costs->{$file};
	    if ($file_costs) {
		my $this_file_total = $file_costs->{"totaltime"};
		if ($this_file_total > $most_expensive_file_total) {
		    $most_expensive_file = $file;
		    $most_expensive_file_total = $this_file_total;
		}
	    }
	}
    }

    return ($most_expensive_file, $most_expensive_file_total);
}

sub compute_cost_paths_aux {
    my $certfile = shift;
    my $deps = shift;
    my $basecosts = shift;
    my $costs = shift;
    my $warnings = shift;

    if (exists $costs->{$certfile} || ! ($certfile =~ /\.(cert|acl2x)$/)) {
	return $costs->{$certfile};
    }

    # put something in $costs->{$certfile} so that we don't loop
    $costs->{$certfile} = 0;

    my $certtime = $basecosts->{$certfile};
    my $certdeps = $deps->{$certfile};

    my $most_expensive_dep = 0;
    my $most_expensive_dep_total = 0;

    if ($certdeps) {
	foreach my $dep (@{$certdeps}) {
	    if ($dep =~ /\.(cert|acl2x)$/) {
		my $this_dep_costs = compute_cost_paths_aux($dep, $deps, $basecosts, $costs, $warnings);
		if (! $this_dep_costs) {
		    if ($dep eq $certfile) {
			push(@{$warnings}, "Self-dependency in $dep");
		    } else {
			push(@{$warnings}, "Dependency loop involving $dep and $certfile");
		    }
		}
	    }
	}

	($most_expensive_dep, $most_expensive_dep_total) = find_most_expensive($certdeps, $costs);
    }
    my %entry = ( "totaltime" => $most_expensive_dep_total +
		                 ($certtime ? $certtime : 0.000001), 
		  "maxpath" => $most_expensive_dep );

    $costs->{$certfile} = \%entry;
    return $costs->{$certfile};
}

sub compute_cost_paths {
    my $deps = shift;
    my $basecosts = shift;
    my $costs = shift;
    my $warnings = shift;
    
    foreach my $certfile (keys %{$deps}) {
	compute_cost_paths_aux($certfile, $deps, $basecosts, $costs, $warnings);
    }
}

	

sub make_costs_table_aux {

# make_costs_table_aux(file, deps, costs, warnings) -> cost
# May modify costs and warnings.
#
# Inputs:
#
#  - Certfile is a string, the name of the file to get the cost for.
#
#  - Deps is a reference to a dependency graph such as is generated by
#    makefile_dependency_graph.
# 
#  - Costs is a reference to the table of costs which we are constructing.

    my $certfile = shift;
    my $deps = shift;
    my $costs = shift;
    my $warnings = shift;
    my $short = shift;

    if (exists $costs->{$certfile}) {
	return $costs->{$certfile};
    }

    # put something in $costs->{$certfile} so that we don't loop
    $costs->{$certfile} = 0;

    my $certtime = get_cert_time($certfile, $warnings);
    my $certdeps = $deps->{$certfile};

    my $most_expensive_dep_total = 0;
    my $most_expensive_dep = 0;

    if ($certdeps) {
	foreach my $dep (@{$certdeps}) {
	    if ($dep =~ /\.(cert|acl2x)$/) {
		my $this_dep_costs = make_costs_table_aux($dep, $deps, $costs, $warnings, $short);
		# check for dependency loop:
		if ($this_dep_costs) {
		    my $this_dep_total = $this_dep_costs->{"totaltime"};
		    if ($this_dep_total > $most_expensive_dep_total) {
			$most_expensive_dep = $dep;
			$most_expensive_dep_total = $this_dep_total;
		    }
		} else {
		    if ($dep eq $certfile) {
			push(@{$warnings}, "Self-dependency in $dep");
		    } else {
			push(@{$warnings}, "Dependency loop involving $dep and $certfile");
		    }
		}
	    }
	}
    }
    my %entry = ( "shortcert" => short_cert_name($certfile, $short),
		  "selftime" => $certtime, 
		  "totaltime" => $most_expensive_dep_total +
		                 ($certtime ? $certtime : 0.000001), 
		  "maxpath" => $most_expensive_dep );

    $costs->{$certfile} = \%entry;
    return $costs->{$certfile};
}


sub make_costs_table {

# make_costs_table (topfile, deps, costs_table, warnings) -> (costs_table, warnings)

# For each cert file in the dependency graph, records a maximum-cost
# path, the path's cost, and the cert's own cost.

    my $certfile = shift;
    my $deps = shift;
    my $costs = shift;
    my $warnings = shift;
    my $short = shift;
    my $maxcost = make_costs_table_aux($certfile, $deps, $costs, $warnings, $short);
    return ($costs, $warnings);
}



sub warnings_report {

# warnings_report(warnings, htmlp) returns a string describing any warnings
# which were encountered during the generation of the costs table, such as for
# missing .time files.

    my $warnings = shift;
    my $htmlp = shift;

    unless (@$warnings) {
	return "";
    }

    my $ret;

    if ($htmlp) {
	$ret = "<dl class=\"critpath_warnings\">\n"
	     . "<dt>Warnings</dt>\n";
	foreach (@$warnings) {
	    chomp($_);
	    $ret .= "<dd>$_</dd>\n";
	}
	$ret .= "</dl>\n\n";
    }

    else  {
	$ret = "Warnings:\n\n";
	foreach (@$warnings) {
	    chomp($_);
	    $ret .= "$_\n";
	}
	$ret .= "\n\n";
    }

    return $ret;
}



sub critical_path_report {

# critical_path_report(costs,htmlp) returns a string describing the
# critical path for file according to the costs_table, either in TEXT or HTML
# format per the value of htmlp.

    my $costs = shift;
    my $basecosts = shift;
    my $savings = shift;
    my $topfile = shift;
    my $htmlp = shift;
    my $short = shift;


    my $ret;

    if ($htmlp) {
	$ret = "<table class=\"critpath_table\">\n"
	     . "<tr class=\"critpath_head\">"
	     . "<th>Critical Path</th>" 
	     . "<th>Time</th>"
	     . "<th>Cumulative</th>"
	     . "</tr>\n";
    }
    else {
	$ret = "Critical Path\n\n"
	     . sprintf("%-50s %10s %10s %10s %10s\n", "File", "Cumulative", "Time", "Speedup", "Remove");
    }

    my $file = $topfile;
    while ($file) 
    {
	my $filecosts = $costs->{$file};
	my $shortcert = short_cert_name($file, $short);
	my $selftime = $basecosts->{$file};
	my $cumtime = $filecosts->{"totaltime"};
	my $filesavings = $savings->{$file};
	my $sp_savings = $filesavings->{"speedup"};
	my $rem_savings = $filesavings->{"remove"};

	my $selftime_pr = $selftime ? human_time($selftime, 1) : "[Error]";
	my $cumtime_pr = $cumtime ? human_time($cumtime, 1) : "[Error]";
	my $spsav_pr = human_time($sp_savings, 1);
	my $remsav_pr = human_time($rem_savings, 1);

	if ($htmlp) {
	    $ret .= "<tr class=\"critpath_row\">"
	 	 . "<td class=\"critpath_name\">$shortcert</td>"
		 . "<td class=\"critpath_self\">$selftime_pr</td>"
		 . "<td class=\"critpath_total\">$cumtime_pr</td>"
		 . "</tr>\n";
	}
	else {
	    $ret .= sprintf("%-50s %10s %10s %10s %10s\n", $shortcert, $cumtime_pr, $selftime_pr, $spsav_pr, $remsav_pr);
	}

	$file = $filecosts->{"maxpath"};
    }

    if ($htmlp) {
	$ret .= "</table>\n\n";
    }
    else {
	$ret .= "\n\n";
    }

    return $ret;
}
	
sub classify_book_time {
    
# classify_book_time(secs) returns "low", "med", or "high".

    my $time = shift;

    return "err" if !$time;
    return "low" if ($time < 30);
    return "med" if ($time < 120);
    return "high";
}


sub individual_files_report {

# individual_files_report(costs,htmlp) returns a string describing the
# self-times of each file in the costs_table, either in either TEXT or HTML
# format, per the value of htmlp.

    my $costs = shift;
    my $basecosts = shift;
    my $htmlp = shift;
    my $short = shift;

    my @sorted = reverse sort { ($costs->{$a}->{"totaltime"} + 0.0) <=> ($costs->{$b}->{"totaltime"} + 0.0) } keys(%{$costs});
    my $ret;
    if ($htmlp) 
    {
	$ret = "<table class=\"indiv_table\">\n"
	     . "<tr class=\"indiv_head\"><th>All Files</th> <th>Cumulative</th> <th>Self</th></tr>\n";
    } else {
	$ret = "Individual File Times\n\n";

    }


    foreach my $name (@sorted)
    {
	my $entry = $costs->{$name};
	my $shortname = short_cert_name($name, $short);
	my $cumul = $entry->{"totaltime"} ? human_time($entry->{"totaltime"}, 1) : "[Error]";
	my $time = $basecosts->{$name} ? human_time($basecosts->{$name}, 1) : "[Error]";
	my $depname = $entry->{"maxpath"} ? short_cert_name($entry->{"maxpath"}, $short) : "[None]";
	my $timeclass = classify_book_time($basecosts->{$name});

	if ($htmlp)
	{
	    $ret .= "<tr class=\"indiv_row\">";
	    $ret .= "<td class=\"indiv_file\">";
	    $ret .= "  <span class=\"indiv_file_name\">$shortname</span><br/>";
	    $ret .= "  <span class=\"indiv_crit_dep\">--> $depname</span>";
	    $ret .= "</td>";
	    $ret .= "<td class=\"indiv_cumul\">$cumul</td>";
	    $ret .= "<td class=\"indiv_time_$timeclass\">$time</td>";
	    $ret .= "</tr>\n";
	} else {
	    $ret .= sprintf("%-50s %10s %10s  --->  %-50s\n",
			    $shortname, $cumul, $time, $depname);
	}
    }
    
    if ($htmlp)
    {
	$ret .= "</table>\n\n";
    } else {
	$ret .= "\n\n";
    }

    return $ret;
}   


sub to_basename {
    my $name = shift;
    $name = canonical_path($name);
    $name =~ s/\.(lisp|cert)$//;
    return $name;
}





my $debugging = 0;
my $clean_certs = 0;
my $print_deps = 0;
my $all_deps = 0;

my %dirs = ( );

sub certlib_add_dir {
    my $name = shift;
    my $dir = shift;
    $dirs{$name} = $dir;
}

sub certlib_set_opts {
    my $opts = shift;
    $debugging = $opts->{"debugging"};
    $clean_certs = $opts->{"clean_certs"};
    $print_deps = $opts->{"print_deps"};
    $all_deps = $opts->{"all_deps"};
}

sub certlib_set_base_path {
    my $dir = shift;
    $dir = $dir || ".";
    $BASE_PATH = abs_canonical_path($dir);
}

sub get_add_dir {
    my $base = shift;
    my $the_line = shift;
    my $local_dirs = shift;

    # Check for ADD-INCLUDE-BOOK-DIR commands
    my $regexp = "^[^;]*\\(add-include-book-dir[\\s]+:([^\\s]*)[\\s]*\"([^\"]*)\\/\"";
    my @res = $the_line =~ m/$regexp/i;
    if (@res) {
	my $name = uc($res[0]);
	my $basedir = dirname($base);
	$local_dirs->{$name} = canonical_path(rel_path($basedir, $res[1]));
	print "Added local_dirs entry " . $local_dirs->{$name} . " for $name\n" if $debugging;
	print_dirs($local_dirs) if $debugging;
	return 1;
    }
}


sub lookup_colon_dir {
    my $name = uc(shift);
    my $local_dirs = shift;

    my $dirpath;
    $local_dirs && ($dirpath = $local_dirs->{$name});
    if (! defined($dirpath)) {
	$dirpath = $dirs{$name} ;
    }
    return $dirpath;
}

sub get_include_book {
    my $base = shift;
    my $the_line = shift;
    my $local_dirs = shift;

    my $regexp = "^[^;]*\\(include-book[\\s]*\"([^\"]*)\"(?:.*:dir[\\s]*:([^\\s)]*))?";
    my @res = $the_line =~ m/$regexp/i;
    if (@res) {
	if ($res[1]) {
	    my $dirpath = lookup_colon_dir($res[1], $local_dirs);
	    unless (defined($dirpath)) {
		print "Warning: Unknown :dir entry $res[1] for $base\n";
		print_dirs($local_dirs) if $debugging;
		return 0;
	    }
	    return canonical_path(rel_path($dirpath, "$res[0].cert"));
	} else {
	    my $dir = dirname($base);
	    return canonical_path(rel_path($dir, "$res[0].cert"));
	}
    }
    return 0;
}

sub get_depends_on {
    my $base = shift;
    my $the_line = shift;
    my $local_dirs = shift;

    my $regexp = "\\(depends-on[\\s]*\"([^\"]*)\"(?:.*:dir[\\s]*:([^\\s)]*))?";
    my @res = $the_line =~ m/$regexp/i;
    if (@res) {
	if ($res[1]) {
	    my $dirpath = lookup_colon_dir($res[1], $local_dirs);
	    unless (defined($dirpath)) {
		print "Warning: Unknown :dir entry $res[1] for $base\n";
		print_dirs($local_dirs) if $debugging;
		return 0;
	    }
	    return canonical_path(rel_path($dirpath, "$res[0]"));
	} else {
	    my $dir = dirname($base);
	    return canonical_path(rel_path($dir, "$res[0]"));
	}
    }
    return 0;
}


# Possible more general way of recognizing a Lisp symbol:
# ((?:[^\\s\\\\|]|\\\\.|(?:\\|[^|]*\\|))*)
# - repeatedly matches either: a non-pipe, non-backslash, non-whitespace character,
#                              a backslash and subsequently any character, or
#                              a pair of pipes with a series of intervening non-pipe characters.
# For now, stick with a dumber, less error-prone method.


sub get_ld {
    my $base = shift;
    my $the_line = shift;
    my $local_dirs = shift;

    # Check for LD commands
    my $regexp = "^[^;]*\\(ld[\\s]*\"([^\"]*)\"(?:.*:dir[\\s]*:([^\\s)]*))?";
    my @res = $the_line =~ m/$regexp/i;
    if (@res) {
	if ($res[1]) {
	    my $dirpath = lookup_colon_dir($res[1], $local_dirs);
	    unless (defined($dirpath)) {
		print "Warning: Unknown :dir entry $res[1] for $base\n";
		print_dirs($local_dirs) if $debugging;
		return 0;
	    }
	    return canonical_path(rel_path($dirpath, $res[0]));
	} else {
	    my $dir = dirname($base);
	    return canonical_path(rel_path($dir, $res[0]));
	}
    }
    return 0;
}


sub newer_than {
    my $file1 = shift;
    my $file2 = shift;
    return ((stat($file1))[9]) > ((stat($file2))[9]);
}

sub excludep {
    my $prev = shift;
    my $dirname = dirname($prev);
    while ($dirname ne $prev) {
	if (-e rel_path($dirname, "cert_pl_exclude")) {
	    return 1;
	}
	$prev = $dirname;
	$dirname = dirname($dirname);
    }
    return 0;
}



sub print_dirs {
    my $local_dirs = shift;
    print "dirs:\n";
    while ( (my $k, my $v) = each (%{$local_dirs})) {
	print "$k -> $v\n";
    }
}

sub scan_ld {
    my $fname = shift;
    my $deps = shift;
    my $local_dirs = shift;

    print "scan_ld $fname\n" if $debugging;

    push (@{$deps}, $fname);
    if (open(my $ld, "<", $fname)) {
	while (my $the_line = <$ld>) {
	    my $incl = get_include_book($fname, $the_line, $local_dirs);
	    my $depend =  $incl || get_depends_on($fname, $the_line, $local_dirs);
	    my $ld = $depend || get_ld($fname, $the_line, $local_dirs);
	    my $add = $ld || get_add_dir($fname, $the_line, $local_dirs);
	    if ($incl) {
		push(@{$deps}, $incl);
	    } elsif ($depend) {
		push(@{$deps}, $depend);
	    } elsif ($ld) {
		push(@{$deps}, $ld);
		scan_ld($ld, $deps, $local_dirs);
	    }
	}
	close($ld);
    } else {
	print "Warning: scan_ld: Could not open $fname: $!\n";
    }
}

sub scan_book {
    my $fname = shift;
    my $deps = shift;
    my $local_dirs = shift;

    print "scan_book $fname\n" if $debugging;

    if ($fname) {
	# Scan the lisp file for include-books.
	if (open(my $lisp, "<", $fname)) {
	    while (my $the_line = <$lisp>) {
		my $incl = get_include_book($fname, $the_line, $local_dirs);
		my $dep = $incl || get_depends_on($fname, $the_line, $local_dirs);
		my $add = $dep || get_add_dir($fname, $the_line, $local_dirs);
		if ($incl) {
		    push(@{$deps},$incl);
		} elsif ($dep) {
		    push(@{$deps}, $dep);
		}
	    }
	    close($lisp);
	} else {
	    print "Warning: scan_book: Could not open $fname: $!\n";
	}
    }
}
    
sub scan_two_pass {
    my $fname = shift;

    print "scan_two_pass $fname\n" if $debugging;

    if ($fname) {
	# Scan the file for ";; two-pass certification"
	if (open(my $file, "<", $fname)) {
	    my $regexp = ";; two-pass certification";
	    while (my $the_line = <$file>) {
		my $match = $the_line =~ m/$regexp/;
		if ($match) {
		    print "two pass: $fname\n" if $debugging;
		    return 1;
		}
	    }
	    close($file);
	}
    }
    return 0;
}
		
    
# Find dependencies o
sub find_deps {
    my $base = shift;
    my $lispfile = $base . ".lisp";

    my $deps = [ $lispfile ];
    my $local_dirs = {};

    # If a corresponding .acl2 file exists or otherwise if a
    # cert.acl2 file exists in the directory, we need to scan that for dependencies as well.
    my $acl2file = $base . ".acl2";
    if (! -e $acl2file) {
	$acl2file = rel_path(dirname($base), "cert.acl2");
	if (! -e $acl2file) {
	    $acl2file = 0;
	}
    }

    # Scan the .acl2 file first so that we get the add-include-book-dir
    # commands before the include-book commands.
    $acl2file && scan_ld($acl2file, $deps, $local_dirs);
    
    # Scan the lisp file for include-books.
    scan_book($lispfile, $deps, $local_dirs);
    
    # If there is an .image file corresponding to this file or a
    # cert.image in this file's directory, add a dependency on the
    # ACL2 image specified in that file and the .image file itself.
    my $imagefile = $base . ".image";
    if (! -e $imagefile) {
	$imagefile = rel_path(dirname($base), "cert.image");
	if (! -e $imagefile) {
	    $imagefile = 0;
	}
    }

    if ($imagefile) {
	push(@{$deps}, canonical_path($imagefile));
	if (open(my $im, "<", $imagefile)) {
	    my $line = <$im>;
	    chomp $line;
	    if ($line && ($line ne "acl2")) {
		my $image = canonical_path(rel_path(dirname($base), $line));
		if (! -e $image) {
		    $image = which($line);
		}
		if (-e $image) {
		    push(@{$deps}, canonical_path($image));
		}
	    }
	    close $im;
	} else {
	    print "Warning: find_deps: Could not open image file $imagefile: $!\n";
	}
    }

    return $deps;

}    
    

# During a dependency search, this is run with $target set to each
# cert and source file in the dependencies of the top-level targets.
# If the target has been seen before, then it returns immediately.
sub add_deps {
    my $target = shift;
    my $seen = shift;
    my $sources = shift;


    if (exists $seen->{$target}) {
	# We've already calculated this file's dependencies.
	return;
    }

    if ($target !~ /\.cert$/) {
	push(@{$sources}, $target);
	$seen->{$target} = 0;
	return;
    }

    if (excludep($target)) {
	$seen->{$target} = 0;
	return;
    }

    print "add_deps $target\n" if $debugging;

    my $local_dirs = {};
    my $base = $target;
    $base =~ s/\.cert$//;
    my $lispfile = $base . ".lisp";

    # Clean the cert and out files if we're cleaning.
    if ($clean_certs) {
	my $outfile = $base . ".out";
	my $timefile = $base . ".time";
	my $compfile = $base . ".lx64fsl";
	unlink($target) if (-e $target);
	unlink($outfile) if (-e $outfile);
	unlink($timefile) if (-e $timefile);
	unlink($compfile) if (-e $compfile);
    }

    # First check that the corresponding .lisp file exists.
    if (! -e $lispfile) {
	print "Error: Need $lispfile to build $target.\n";
	return;
    }

    my $deps = find_deps($base);

    if (scan_two_pass($lispfile)) {
	my $acl2xfile = $base . ".acl2x";
	$seen->{$target} = [ $acl2xfile ];
	$seen->{$acl2xfile} = $deps;
    } else {
	$seen->{$target} = $deps;
    }

    if ($print_deps) {
	print "Dependencies for $target:\n";
	foreach my $dep (@{$deps}) {
	    print "$dep\n";
	}
	print "\n";
    }

    # Run the recursive add_deps on each dependency.
    foreach my $dep  (@{$deps}) {
	add_deps($dep, $seen, $sources);
    }
    

    # If this target needs an update or we're in all_deps mode, we're
    # done, otherwise we'll delete its entry in the dependency table.
    unless ($all_deps) {
	my $needs_update = (! -e $target);
	if (! $needs_update) {
	    foreach my $dep (@{$deps}) {
		if ((-e $dep && newer_than($dep, $target)) || $seen->{$dep}) {
		    $needs_update = 1;
		    last;
		}
	    }
	}
	if (! $needs_update) {
	    $seen->{$target} = 0;
	}
    }

}

sub read_targets {
    my $fname=shift;
    my $targets=shift;
    if (open (my $tfile, $fname)) {
	while (my $the_line = <$tfile>) {
	    chomp($the_line);
	    $the_line =~ m/^\s*([^\#]*[^\#\s])?/;
	    my $fname = $1;
	    if ($fname && (length($fname) > 0)) {
		push (@{$targets}, $fname);
	    }
	}
	close $tfile;
    } else {
	print "Warning: Could not open $fname: $!\n";
    }
}

# The following "1" is here so that loading this file with "do" or "require" will succeed:
1;
