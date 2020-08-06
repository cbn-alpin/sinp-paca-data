import click
import operator
import itertools


def print_msg(msg):
    click.echo(click.style(msg, fg='yellow'))


def print_info(msg):
    click.echo(click.style(msg, fg='white', bold='true'))


def print_error(msg):
    click.echo(click.style(msg, fg='red'))


def print_verbose(msg):
    click.echo(click.style(msg, fg='black'))


def find_ranges(data):
    """Yield range of consecutive numbers."""
    ranges = []
    for k,g in itertools.groupby(enumerate(data),lambda x:x[0]-x[1]):
        group = (map(operator.itemgetter(1),g))
        group = list(map(int,group))
        ranges.append((group[0],group[-1]))
    return ranges
