<?php

$h = "fer[1-5][a-b][1,3-4].kgb.cnz.alimama.com";
define("DEBUG",1);
#in 1-9
#in a-g

#$s = "fer[1-2,3-5,7,9][a-b][1-4].kgb.cnz.alimama.com";
function scope2array($s = '')
{
    $a = array();

    $s .= ',';
    $dotarr = split(",", $s);
    foreach ($dotarr as $sa) {
        $sa = trim($sa);
        if(!$sa) continue;

        $f = ''; $e = '';
        if(preg_match('/^(.+)\-(.+)$/', $sa, $m)) {
        #if(preg_match('/(.+)(.+)/', $s, $m)) {
            $f = $m[1]; $e = $m[2];
            for($i=$f; $i<=$e; $i++) {
                array_push($a, $i);
            }
        } else if($sa){
                array_push($a, $sa);
        } else {
            printf("ERROR:in scope2array, preg_match error, sa = A%sB\n", $sa);
        }
    }
    if(PARSE2ARRAY_DEBUG) {
        printf("DEBUG:in scope2array, scope = $s, return array = \n" . print_r($a,1));
    }
    return $a;
}

function cartesianhns($arr1, $arr2)
{
    $retarr = array();
    foreach (array_keys($arr1) as $k) {
        foreach ($arr2 as $v) {
            array_push($retarr, $arr1[$k].$v);
        }
    }
    if(PARSE2ARRAY_DEBUG) {
        printf("DEBUG:in cartesianhns, input array arr1: " . print_r($arr1,1) . "\narr2:" . print_r($arr2,1));
        printf("\nreturn array : " . print_r($retarr,1)); 
    }
    return $retarr;
}

function parse2array($h = '')
{
    if(!$h) {
        return array();
    }

    $hns = array();
    $hn = '';

    $len = strlen($h);

    $prefix = '';
    $scope = '';
    $in_scope = 0;

    for($i=0;$i<$len;$i++) {
        $c = $h[$i];
        printf("DEBUG: c = %s, scope = %s, prefix = %s\n", $c, $scope, $prefix);
        if($c === '[') {
            $in_scope = 1;
            if(count($hns) == 0) {
                array_push($hns,$prefix);
            }else{ 
                $hns = cartesianhns($hns,array($prefix));
            }
            $scope = ''; $prefix = '';
        }else if($c === '-') {
            $scope .= $c;

        }else if($c === ',') {
            $scope .= $c;
        }else if($c === ']') {
            $in_scope = 0;
            $a1 = scope2array($scope);
            $hns = cartesianhns($hns,$a1);
            $scope = ''; $prefix = '';
        }else{
            if($in_scope) {
                $scope .= $c;
            } else {
                $prefix .= $c;
            }
        }
    }
    if($prefix) {
        $hns = cartesianhns($hns,array($prefix));
    }
#$h = "fer[1-5][a-b][1,3-4].kgb.cnz.alimama.com";
    if(PARSE2ARRAY_DEBUG) {
        printf("prefix = %s\n", $prefix);
        printf("scope = %s\n", $scope);
        printf("hostnames array = " . print_r($hns,1));
    }
    return $hns;
}

function parse2array_test() 
{
    $h = "fer[1-5][a-b][1-5].kgb.cnz.alimama.com";
    $h = "fer1[aa,bb,cc]1.kgb.cnz.alimama.com";
    $h = "fer[1-5][a,b][1-5].kgb.cnz.alimama.com";
    $h = "[fe,mg]r[1-5][a,b][1-5].kgb.cnz.alimama.com";
    $h = "fer[1-2,3-5,9,11][a-b]1.kgb.cnz.alimama.com";
    parse2array($h);
    if(PARSE2ARRAY_DEBUG) {
        printf("DEBUG: h = %s\n", $h);
    }
}
parse2array_test();
?>
