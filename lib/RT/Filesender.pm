package RT::Filesender;

use strict;
use warnings;

use RT::Article;
use RT::IR;
use JSON;
use LWP::UserAgent;
use Digest::SHA qw(hmac_sha1_hex);
use URI::Split qw(uri_split uri_join);
use IO::Socket::SSL;

sub RequestFile {
    my $self = shift;
    my $Ticket = shift;

    return 0 unless $Ticket->CurrentUserHasRight('ModifyTicket');

    my $commentAddress = "";
    if ($Ticket->QueueObj->CommentAddress) {
        $commentAddress = $Ticket->QueueObj->CommentAddress;
    } else {
        $commentAddress = RT->Config->Get('CommentAddress');
    }

    if ($commentAddress eq "") {
        RT->Logger->error(
            "Ticket Queue does not have comment address and default comment address not set. Stopping file request..."
        );

        return 0;
    }

    my $article = RT::Article->new(RT->SystemUser);
    unless ($article->Load(RT->Config->Get('FilesenderMessageArticleId'))) {
        RT->Logger->error("Failed loading Article by FilesenderMessageArticleId");

        return 0;
    }

    my $message = $article->FirstCustomFieldValue('Content');

    my @requestors = ();

    if ($Ticket->RequestorAddresses) {
        @requestors = sort(
            map {
                s/^\s+//;  # strip leading spaces
                s/\s+$//;  # strip trailing spaces
                $_         # return the modified string
            }
                split ',', $Ticket->RequestorAddresses
        );
    } else {
        @requestors = ($Ticket->OwnerObj->EmailAddress);
    }

    my $requestors_count = scalar @requestors;

    unless ($requestors_count > 0) {
        RT->Logger->error("No requestors to send file request to");

        return 0;
    }

    my $tag = $Ticket->QueueObj->SubjectTag || "";
    if ($tag eq "") {
        $tag = RT->Config->Get('rtname');
    }

    for my $requestor (@requestors) {
        my $subject = sprintf("[%s #%d] %s", $tag, $Ticket->Id, $Ticket->Subject);

        my $id = create_guest(
            $commentAddress,
            $requestor,
            $subject,
            $message
        );

        next unless $id;

        RT->Logger->info(
            sprintf("File request created for ticket #%d requestor %s (guest ID: %d)", $Ticket->Id, $requestor, $id)
        );

        $Ticket->Comment(Content => sprintf(
            "File request sent\nFrom: %s\nTo: %s\nSubject: %s\n\nContent: %s",
            $commentAddress,
            $requestor,
            $subject,
            $message)
        );
    }

    return 1;
}

sub create_guest {
    my ($from, $to, $subject, $message) = @_;

    my %guest_options = (
        'email_upload_started' => 0,
        'email_upload_page_access' => 0,
        'valid_only_one_time' => 1,
        'does_not_expire' => 0,
        'can_only_send_to_me' => 1,
        'email_guest_created' => 1,
        'email_guest_created_receipt' => 1,
        'email_guest_expired' => 1
    );
    my %transfer_options = (
        'email_me_copies' => 0,
        'email_me_on_expire' => 1,
        'email_upload_complete' => 0,
        'email_download_complete' => 0,
        'email_daily_statistics' => 0,
        'add_me_to_recipients' => 0,
        'get_a_link' => 0
    );

    my %options = ('guest' => \%guest_options, 'transfer' => \%transfer_options);

    my %data    = (
        subject    => $subject,
        from       => $from,
        message    => $message,
        recipient  => $to,
        options    => \%options
    );

    my $timestamp = time();
    my $api_url   = RT->Config->Get('FilesenderApiUrl');

    my %query_params = (
        remote_application => RT->Config->Get('FilesenderRemoteApplication'),
        timestamp          => $timestamp
    );

    my $signable_url = sprintf("%s/guest", $api_url);
    $signable_url =~ s!^https?://!!i;

    my $to_sign = sprintf("post&%s?%s&%s", $signable_url, build_query_string(%query_params), encode_json(\%data));

    $query_params{signature} = hmac_sha1_hex($to_sign, RT->Config->Get('FilesenderSecret'));

    my $url = sprintf("%s/guest", $api_url);

    RT->Logger->info(
        sprintf("[Filesender]: sending request to %s", $url .  '?' . build_query_string(%query_params))
    );

    my $client = build_http_client();

    my $response = $client->post(
        $url .  '?' . build_query_string(%query_params),
        Content      => encode_json(\%data),
        Content_Type => 'application/json'
    );

    unless ($response->is_success) {
        RT->Logger->error(sprintf("[Filesender]: %s", $response->content));

        return undef;
    }

    my $response_data = decode_json($response->content);

    return $response_data->{id};
}

sub build_http_client {
    {
        my  $client = LWP::UserAgent->new;

        if (RT->Config->Get('FilesenderSkipSSLVerification')) {
            $client->ssl_opts(
                SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE,
                verify_hostname => 0
            );
        }

        return $client;
    }
}

sub build_query_string {
    my %params = @_;

    my @query;

    foreach my $key (sort keys %params) {
        push @query, sprintf("%s=%s", $key, $params{$key});
    }

    return join('&', @query);
}

1;