<?php
# This code can be used to test your php memory_limit settings.
# Tony Baltazar. root[@]rubyninja.org

ini_set('display_errors', true);

while (1) {
	echo 'Hello' . nl2br("\n");
	$array = array(1,2);

	while(1) {
		$tmp = $array;
		$array = array_merge($array, $tmp);
		echo memory_get_usage() . nl2br("\n");
		flush();
		sleep(1);
	}	
}
