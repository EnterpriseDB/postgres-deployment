import argparse

from ..options import *

DEFAULT_SUBCOMMANDS = {
    'configure': {
        'help': 'Project configuration',
        'project_argument': True,
    },
    'provision': {
        'help': 'Machine provisioning',
        'project_argument': True,
    },
    'destroy': {
        'help': 'Machines destruction',
        'project_argument': True,
    },
    'deploy': {
        'help': 'Postgres deployment',
        'project_argument': True,
    },
    'show': {
        'help': 'Show configuration',
        'project_argument': True,
    },
    'display': {
        'help': 'Display project details',
        'project_argument': True,
    },
    'passwords': {
        'help': 'Display project passwords',
        'project_argument': True,
    },
    'list': {
        'help': 'List projects',
        'project_argument': False,
    },
    'setup': {
        'help': 'Install prerequisites',
        'project_argument': False,
    },
    'specs': {
        'help': 'Show Cloud default specifications',
        'project_argument': False,
    },
    'logs': {
        'help': 'Show project logs',
        'project_argument': True,
    },
    'remove': {
        'help': 'Remove project',
        'project_argument': True,
    },
}

def default_subcommand_parsers(subparser, available_subcommands):
    parsers = {}
    for subcommand in available_subcommands:
        # Is this sub-command defined in DEFAULT_SUBCOMMANDS?
        if not DEFAULT_SUBCOMMANDS.get(subcommand):
            raise Exception(
                "Sub-command %s not found in DEFAULT_SUBCOMMANDS" % subcommand
            )

        # Add new parser for the sub-command
        parsers[subcommand] = subparser.add_parser(
            subcommand, help=DEFAULT_SUBCOMMANDS[subcommand]['help']
        )

        # Define project argument
        if DEFAULT_SUBCOMMANDS[subcommand]['project_argument'] is True:
            parsers[subcommand].add_argument(
                'project', type=ProjectType, metavar='<project-name>',
                help='Project name'
            ).completer = project_name_completer

    return parsers
