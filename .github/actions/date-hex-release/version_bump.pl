#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use POSIX qw(strftime);

my $commit = 0;
my $commit_message_prefix = '[DEPLOY]';
my $date;
my $github_output;
my $source_ref_file;
my $version_file = 'mix.exs';

GetOptions(
    'commit'                    => \$commit,
    'commit-message-prefix=s'   => \$commit_message_prefix,
    'date=s'                    => \$date,
    'github-output=s'           => \$github_output,
    'source-ref-file=s'         => \$source_ref_file,
    'version-file=s'            => \$version_file,
) or die "Usage: $0 [--commit] [--date YYYY-MM-DD] [--github-output PATH] [--source-ref-file PATH] [--version-file PATH]\n";

$date //= strftime("%Y-%m-%d", gmtime());

my ($year, $month, $day) = $date =~ /\A(\d{4})-(\d{2})-(\d{2})\z/
    or die "Date must use YYYY-MM-DD format\n";

my $tag_prefix = join('.', $year, $month, $day);
my $sequence = next_sequence($tag_prefix);
my $hex_version = join('.', $year % 100, int("$month$day"), $sequence);
my $git_tag = sprintf('%s.%02d', $tag_prefix, $sequence);

print "Hex version: $hex_version\n";
print "Git tag: $git_tag\n";

write_github_output($github_output, 'hex_version', $hex_version);
write_github_output($github_output, 'git_tag', $git_tag);

exit 0 unless $commit;

ensure_clean_worktree();
update_mix_file($version_file, $hex_version);
update_source_ref_file($source_ref_file, $git_tag) if $source_ref_file;
run_system('git', 'add', '--', $version_file);
run_system('git', 'add', '--', $source_ref_file) if $source_ref_file && $source_ref_file ne $version_file;
run_system('git', 'commit', '-m', "$commit_message_prefix bump version to $hex_version");

sub next_sequence {
    my ($prefix) = @_;
    my $maximum = 0;

    for my $tag (split /\n/, run_cmd("git tag --list '$prefix.*'")) {
        next unless $tag =~ /^\Q$prefix\E\.(\d+)$/;
        $maximum = $1 if $1 > $maximum;
    }

    return $maximum + 1;
}

sub update_source_ref_file {
    my ($mix_file, $git_tag) = @_;

    open(my $input, '<', $mix_file) or die "Cannot read $mix_file: $!\n";
    my @lines = <$input>;
    close($input);

    my $updated = 0;

    for my $line (@lines) {
        $updated += $line =~ s/\@source_ref\s+"[^"]+"/\@source_ref "$git_tag"/;
    }

    die "Couldn't find exactly one \@source_ref in $mix_file\n" unless $updated == 1;

    open(my $output, '>', $mix_file) or die "Cannot write $mix_file: $!\n";
    print {$output} @lines;
    close($output);
}

sub ensure_clean_worktree {
    die "Working tree must be clean before creating a release commit\n"
        unless run_cmd('git status --short') eq '';
}

sub update_mix_file {
    my ($mix_file, $version) = @_;

    open(my $input, '<', $mix_file) or die "Cannot read $mix_file: $!\n";
    my @lines = <$input>;
    close($input);

    my $updated = 0;

    for my $line (@lines) {
        $updated += $line =~ s/version:\s*"[^"]+"/version: "$version"/;
        $updated += $line =~ s/\@version\s+"[^"]+"/\@version "$version"/;
    }

    die "Couldn't find exactly one hardcoded version in $mix_file\n" unless $updated == 1;

    open(my $output, '>', $mix_file) or die "Cannot write $mix_file: $!\n";
    print {$output} @lines;
    close($output);
}

sub write_github_output {
    my ($path, $key, $value) = @_;
    return unless defined $path;

    open(my $output, '>>', $path) or die "Cannot write $path: $!\n";
    print {$output} "$key=$value\n";
    close($output);
}

sub run_cmd {
    my ($command) = @_;
    my $output = `$command 2>&1`;
    my $exit_code = $? >> 8;

    die "Command failed: $command\n$output\n" if $exit_code != 0;

    chomp($output);
    return $output;
}

sub run_system {
    my (@command) = @_;
    system(@command) == 0
        or die "Command failed: @command\n";
}
