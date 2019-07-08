#!/usr/bin/env php
<?php
# Simple Cloudflare cache purging script.
# NOTE: This script only works with accounts with less than 100 domains.
# Written by: Tony Baltazar. July 2019.
# Email: root[@]rubyninja.org

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

// CLI Options
$shortopts  = '';
$shortopts .= 'd:';
$shortopts .= 'l';
$shortopts .= 'h';
$longopts   = ['domain:', 'files:', 'hosts:', 'tags:', 'list', 'help'];
$options = getopt($shortopts, $longopts);

// Required Environment Variables
$config = [
    'CF_EMAIL' => false,
    'CF_KEY'   => false
];

foreach($config as $setting => $value) {
    $config[$setting] = getenv($setting);

    if (!$config[$setting]) {
        echo "$setting Environment variable is not set!\n";
        exit(1);
    }
}


if (array_key_exists('help', $options) || array_key_exists('h', $options)) {
    usage();

} elseif (array_key_exists('list', $options) || array_key_exists('l', $options)) {
    $domains = get_domain_ids();
    if(!$domains) exit(1);

    echo "Domains available:\n";
    foreach($domains as $domain)
        echo $domain . "\n";

} elseif (array_key_exists('domain', $options) || array_key_exists('d', $options)) {
    if(array_key_exists('domain', $options))  $domain = $options['domain'];
    if(array_key_exists('d', $options))       $domain = $options['d'];

    $domain_zone_id = get_domain_ids($domain);
    if(!$domain_zone_id) exit(1);

    if(array_key_exists('files', $options))
        purge($domain_zone_id, 'files');

    if(array_key_exists('hosts', $options))
        purge($domain_zone_id, 'hosts');

    if(array_key_exists('tags', $options))
        purge($domain_zone_id, 'tags');

    if((!array_key_exists('files', $options)) && (!array_key_exists('hosts', $options)) && (!array_key_exists('tags', $options)))
        purge($domain_zone_id, 'all');

} else {
    usage();
}



// Get our domains zone id's
function get_domain_ids($domain='all') {
    global $config;

    $ch = curl_init();

    curl_setopt($ch, CURLOPT_URL, 'https://api.cloudflare.com/client/v4/zones?per_page=100');
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 20);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER,[
        "X-Auth-Email: ${config['CF_EMAIL']}",
        "X-Auth-Key: ${config['CF_KEY']}",
        "Content-Type: application/json"]
    );

    try {
        $response = curl_exec($ch);

        if ($response === false)
            throw new Exception( curl_error($ch) );

    } catch (Exception $e) {
        echo "Curl request error:\n" . $e->getMessage() . "\n";
        exit(1);
    }

    $decoded_response = json_decode($response);

    if($decoded_response->success) {
        if($domain == 'all') {
            $all_domains = [];

            foreach($decoded_response->result as $domain_in_cf) {
                $all_domains[] = $domain_in_cf->name;
            }

            return $all_domains;
        } else {
            foreach($decoded_response->result as $domain_in_cf) {
                if($domain == $domain_in_cf->name)
                    return $domain_in_cf->id;
            }

            echo "ERROR: Domain $domain not found!\n";
            return false;
        }
    } else {
        echo "ERROR: Failed to get zone ids!\n";
        foreach($decoded_response->errors as $message => $error) {
            echo "code: "    . $error->code . "\n";
            echo "message: " . $error->message . "\n";
        }

        return false;
    }
 
}

// Purge cache
function purge($zone_id, $purge_type) {
    global $config, $options;

    $ch = curl_init();

    switch($purge_type) {
        case 'all':
            $post_field = '{"purge_everything":true}';
            break;
        case 'files':
            $post_field = '{"files":["' . $options['files'] . '"]}';
            break;
        case 'hosts':
            $post_field = '{"hosts":["' . $options['hosts'] . '"]}';
            break;
        case 'tags':
            $post_field = '{"tags":["' . $options['tags'] . '"]}';
            break;
        default:
            echo "Unknown purge() argument type";
            return false;
    }

    curl_setopt($ch, CURLOPT_URL, "https://api.cloudflare.com/client/v4/zones/$zone_id/purge_cache");
    curl_setopt($ch, CURLOPT_POSTFIELDS, $post_field);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 20);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER,[
        "X-Auth-Email: ${config['CF_EMAIL']}",
        "X-Auth-Key: ${config['CF_KEY']}",
        "Content-Type: application/json"]
    );

    try {
        $response = curl_exec($ch);

        if ($response === false)
            throw new Exception( curl_error($ch) );

    } catch (Exception $e) {
        echo "Curl request error:\n" . $e->getMessage() . "\n";
        exit(1);
    }

    $decoded_response = json_decode($response);

    if($decoded_response->success) {
        echo "Successfully purge $purge_type Cloudflare cache for zone id $zone_id.\n";
        return true;

    } else {
        echo "ERROR: Failed purging cache for $zone_id!\n";
        foreach($decoded_response->errors as $message => $error) {
            echo 'Code: '    . $error->code . "\n";
            echo 'Message: ' . $error->message . "\n";
        }

        return false;
    }
}


function usage() {
    echo "Usage : cloudflare-purge.php --domain example.com [--tags <tags> | --hosts <hostnames> | --files <files>]\n";
    echo " --domain   | -d  : Domain name.\n\n";
    echo " Optionally,\n";
    echo " Type of purge, by default all caching is purge. Comma separated if more than one value.\n";
    echo "    --tags  |  Tags you want to purge. \n";
    echo "    --hosts |  Hostnames you want to purge. \n";
    echo "    --files |  Files you want to purge. \n\n";
    echo " --list     | -l  : List domains avaible.\n";
    echo " --help     | -h  : Help message.\n\n";
}
    
