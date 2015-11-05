from django.conf.urls import patterns, url

urlpatterns = patterns('core.views',
    # For testing
    url(r'^hello/', 'hello', name='core_hello'),
    url(r'^echo/', 'echo', name='core_echo'),
    url(r'^dumpmeta/', 'dumpmeta', name='core_dumpmeta'),
    url(r'^dumpupload/', 'dumpupload', name='core_dumpupload'),
    url(r'^hello_with_basic_auth/', 'hello_with_basic_auth', name='core_hello_with_basic_auth'),
    url(r'^hello_with_digest_auth/', 'hello_with_digest_auth', name='core_hello_with_digest_auth'),
)

urlpatterns += patterns('core.playground',
    # Playground
    url(r'^playground/hello/', 'hello', name='core_playground_hello'),
    url(r'^playground/echo/', 'echo', name='core_playground_echo'),
    url(r'^playground/dumpmeta/', 'dumpmeta', name='core_playground_dumpmeta'),
    url(r'^playground/dumpupload/', 'dumpupload', name='core_playground_dumpupload'),
    url(r'^playground/hello_with_basic_auth/', 'hello_with_basic_auth', name='core_playground_hello_with_basic_auth'),
)
