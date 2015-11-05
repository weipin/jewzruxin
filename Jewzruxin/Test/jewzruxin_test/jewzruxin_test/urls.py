from django.conf.urls import patterns, include, url

import core

urlpatterns = patterns('',
    # Examples:
    # url(r'^$', 'jewzruxin_test.views.home', name='home'),
    # url(r'^blog/', include('blog.urls')),

    url(r'^$', 'core.views.home', name='core_home'),
    url(r'^core/', include('core.urls')),
)
