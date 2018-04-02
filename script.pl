# Download bing backgroud photo and set it as desktop backgroud for win10.
use strict;
use warnings;
use LWP::UserAgent;
use Win32::API;
use Win32::Registry;
use JSON;

# set the download directory
my $photos_dir = "D:\\Libraries\\Pictures\\BingPhotos";

# get date
my ( $mday, $mon, $year ) = ( localtime( time() ) )[ 3, 4, 5 ];
my $format_time = sprintf( "%d-%d-%d", $year + 1990, $mon + 1, $mday );

# create agent
my $ua = LWP::UserAgent->new( ssl_opts => { verify_hostname => 1 } );
$ua->timeout(10);
$ua->env_proxy;

# get the photo url
sub getImageUrl ($) {
    my $ua = shift;
    my $n  = 0;
    while ( $n < 10 ) {
        my $response =
          $ua->get(
            "https://cn.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1");
        if ( $response->is_success ) {
            my $html = $response->decoded_content;
            my $json = decode_json $html;
            return "https://cn.bing.com" . $json->{images}[0]{url};
        }
        $n++;
    }
    return 0;
}

# download the photo
my $photo_url = getImageUrl($ua);
die if $photo_url eq 0;
my $photo_path = "$photos_dir\\$format_time.jpg";
my $n          = 0;
while ( $n < 10 ) {
    my $response = $ua->get($photo_url);
    if ( $response->is_success ) {
        my $image_bin = $response->decoded_content( charset => 'none' );
        open my $fh, ">", $photo_path or die;
        binmode $fh;
        print $fh $image_bin;
        close $fh;
        last;
    }
    $n++;
}
die if $n == 10;

# set desktop backgroud by setting the registry
my $tip;
$HKEY_CURRENT_USER->Open( "Control Panel\\Desktop", $tip );
$tip->SetValueEx( "Wallpaper", 0, REG_SZ, $photo_path );
$tip->Close();

# refresh realtime
my $function = Win32::API->new( 'user32.dll',
'BOOL SystemParametersInfo(UINT uiAction,UINT uiParam,PVOID pvParam,UINT fWinIni)'
);
$function->Call( 0x0014, 0, $photo_path, 2 );
