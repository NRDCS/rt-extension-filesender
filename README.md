NAME
    
    RT-Extension-Filesender - RT modifications for Filesender integration

RT VERSION
    
    Works with RT > 4.2.0

INSTALLATION

    perl Makefile.PL
    make
    make install
    
    May need root permissions

    Edit your /opt/rt4/etc/RT_SiteConfig.pm, add this line:

            Plugin('RT::Extension::Filesender');

    Clear your mason cache
            rm -rf /opt/rt4/var/mason_data/obj

    Restart your webserver

CONFIGURATION

    Add to `/opt/rt4/etc/RT_SiteConfig.pm`:
    
    Set(@FilesenderAwareQueues, qw(Queue1 Queue2));
    Set($FilesenderMessageArticleId, <article-id>);
    Set($FilesenderApiUrl, "https://<file-sender-domain>/rest.php");
    Set($FilesenderRemoteApplication, "request_tracker");
    Set($FilesenderSecret, "<secret-in-filesender-config>");
    
    Optional:
    
    Set($FilesenderSkipSSLVerification, 1);
