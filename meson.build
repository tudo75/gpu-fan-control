# project name and programming language
project('com.github.tudo75.gpu-fan-control', ['vala', 'c'], version: '1.0.0')

assert('com.github.tudo75.gpu-fan-control.gschema.xml'==meson.project_name() + '.gschema.xml', 'proj name and gschema file not the same')

# Include the translations module
i18n = import('i18n')
# define GETTEXT_PACKAGE
add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')
# Set our translation domain
add_global_arguments(['-DG_LOG_DOMAIN="@0@"'.format (meson.project_name())], language:'c')


# Include the gnome module
gnome = import('gnome')

# add resources to the executeable
dependencies = [
	dependency('gtk+-3.0', version: '>= 3.20'),
	dependency('glib-2.0'),
]

sources = files(
    'src/Application.vala',
)

sources += gnome.compile_resources(
    meson.project_name() + '.resources',
    'resources/com.github.tudo75.gpu-fan-control.gresource.xml',
    source_dir: 'resources',
)

executable(
    meson.project_name(),
    sources,
    dependencies: dependencies,
    install: true,
)

subdir('po')
subdir('resources')

# dcreate api documentation from code
valadoc = find_program(
    'valadoc',
    required: false,
)
docsrc = [
    '../src/Application.vala',
]

doc = custom_target(
    'documentation',
	output: 'doc',
	command: [
        valadoc, 
        '--verbose',
        '--force',
        '--internal',
        '--private',
        '--use-svg-images',
        '--package-name=GpuFanControl',
        '--package-version=1.0.0',
        '--pkg=gtk+-3.0',
        '--pkg=glib-2.0',
        '--directory=../doc',
        '--target-glib=auto',
        # '--import=gtk+-3.0',
        docsrc
    ],
)


meson.add_install_script('build-aux/post_install.py')
