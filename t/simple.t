use Test2::V0;

use HTTP::Response;
use LWP::UserAgent;
use NOAA::Aurora;

my $aurora = NOAA::Aurora->new();

my @responses = do {
    local $/ = undef;   # Slurp each section
    split /^__EOF__$/m, <DATA>;
};

my $base    = 'https://services.swpc.noaa.gov';
my $content = $responses[0];
my $request = "";
my $mock    = Test2::Mock->new(
    class    => 'LWP::UserAgent',
    track    => 1,
    override => [
        get =>
            sub {
                $request = $_[1];
                return HTTP::Response->new(200, 'SUCCESS', undef, $content);
                },
    ],
);

subtest 'constructor' => sub {
    is($aurora->{cache}, 120, 'default cache');
    $aurora = NOAA::Aurora->new(cache => 60);
    is($aurora->{cache}, 60, 'set cache');
};

subtest 'get_image' => sub {
    $content = 'IMGDATA1';
    my $url = "$base/images/animations/ovation";
    my $img = $aurora->get_image();
    is($request, "$url/north/latest.jpg", 'Request north default');
    is($img, $content, 'Got content');
    $content = 'IMGDATA2';
    $img = $aurora->get_image();
    is($img, 'IMGDATA1', 'Cached content');
    $img = $aurora->get_image(hemisphere => 'south');
    is($request, "$url/south/latest.jpg", 'Request south');
    is($img, $content, 'Got fresh content');
    $img = $aurora->get_image(hem => 's');
    is($request, "$url/south/latest.jpg", 'Still south');

    $aurora = NOAA::Aurora->new(cache => 0);
    $img = $aurora->get_image();
    is($img, $content, 'New content');
    $content = 'IMGDATA3';
    $img = $aurora->get_image();
    is($img, $content, 'No cache');

    # Try output to temp file
};

subtest 'get_forecast' => sub {
    $content = $responses[0];
    my $forecast = $aurora->get_forecast(format => 'text');
    is($request, "$base/text/3-day-forecast.txt", '3 day forecast');
    use Data::Dumper;
    is($forecast, $responses[0], 'Raw content as expected');
    $forecast = $aurora->get_forecast();
    warn Dumper($forecast);
    is($request, "$base/text/3-day-forecast.txt", '3 day geomag forecast');
};

subtest 'get_outlook' => sub {
    $content = $responses[1];

    my $outlook = $aurora->get_outlook(format => 'text');
    is($request, "$base/text/27-day-outlook.txt", '27 day outlook');
    is($outlook, $responses[1], 'Content as expected');
    $outlook = $aurora->get_outlook();
};


done_testing;


__DATA__
:Product: 3-Day Forecast
:Issued: 2025 Jul 03 0030 UTC
# Prepared by the U.S. Dept. of Commerce, NOAA, Space Weather Prediction Center
#
A. NOAA Geomagnetic Activity Observation and Forecast

The greatest observed 3 hr Kp over the past 24 hours was 2 (below NOAA
Scale levels).
The greatest expected 3 hr Kp for Jul 03-Jul 05 2025 is 4.67 (NOAA Scale
G1).

NOAA Kp index breakdown Jul 03-Jul 05 2025

             Jul 03       Jul 04       Jul 05
00-03UT       4.67 (G1)    2.67         3.00     
03-06UT       4.67 (G1)    4.00         2.67     
06-09UT       4.00         3.00         2.33     
09-12UT       2.67         2.67         2.00     
12-15UT       2.33         1.67         2.33     
15-18UT       2.67         1.67         2.33     
18-21UT       3.00         2.00         2.33     
21-00UT       3.67         2.67         2.67     

Rationale: G1 (Minor) geomagnetic storm levels are likely on 03 Jul due
to the arrival of the 28 Jun CME.

B. NOAA Solar Radiation Activity Observation and Forecast

Solar radiation, as observed by NOAA GOES-18 over the past 24 hours, was
below S-scale storm level thresholds.

Solar Radiation Storm Forecast for Jul 03-Jul 05 2025

              Jul 03  Jul 04  Jul 05
S1 or greater    1%      1%      1%

Rationale: No S1 (Minor) or greater solar radiation storms are expected.
No significant active region activity favorable for radiation storm
production is forecast.

C. NOAA Radio Blackout Activity and Forecast

No radio blackouts were observed over the past 24 hours.

Radio Blackout Forecast for Jul 03-Jul 05 2025

              Jul 03        Jul 04        Jul 05
R1-R2           15%           15%           15%
R3 or greater    1%            1%            1%

Rationale: A slight chance for R1-R2 (Minor-Moderate) radio blackouts
due to isolated M-class flare activity will persist through 05 July.
__EOF__
:Product: 27-day Space Weather Outlook Table 27DO.txt
:Issued: 2025 Mar 24 0202 UTC
# Prepared by the US Dept. of Commerce, NOAA, Space Weather Prediction Center
# Product description and SWPC contact on the Web
# https://www.swpc.noaa.gov/content/subscription-services
#
#      27-day Space Weather Outlook Table
#                Issued 2025-03-24
#
#   UTC      Radio Flux   Planetary   Largest
#  Date       10.7 cm      A Index    Kp Index
2025 Mar 24     170          20          5
2025 Mar 25     170          30          6
2025 Mar 26     165          20          5
2025 Mar 27     160          15          4
2025 Mar 28     160          12          4
2025 Mar 29     160           8          3
2025 Mar 30     165           5          2
2025 Mar 31     165           5          2
2025 Apr 01     170           5          2
2025 Apr 02     170           5          2
2025 Apr 03     175          10          3
2025 Apr 04     180          20          5
2025 Apr 05     180          35          6
2025 Apr 06     180          10          3
2025 Apr 07     180          12          4
2025 Apr 08     180          30          5
2025 Apr 09     185          40          6
2025 Apr 10     185          25          5
2025 Apr 11     185          18          5
2025 Apr 12     180          10          3
2025 Apr 13     175          15          5
2025 Apr 14     170          12          4
2025 Apr 15     170           8          3
2025 Apr 16     165           5          2
2025 Apr 17     160          10          3
2025 Apr 18     160          12          4
2025 Apr 19     160           8          3
__EOF__
