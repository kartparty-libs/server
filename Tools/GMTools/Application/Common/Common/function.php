<?php
/**
 * @param $url POST地址
 * @param $data POST内容
 * @return mixed 返回URL相应内容
 */
function postData($url, $data)
{
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 30);
    $handles = curl_exec($ch);
    if (curl_errno($ch)) {
        echo 'Error' . curl_error($ch);//捕抓异常
    }
    curl_close($ch);
    return json_decode($handles, true);
}

function postContent($url, $data)
{
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 30);
    $handles = curl_exec($ch);
    if (curl_errno($ch)) {
        echo 'Error' . curl_error($ch);//捕抓异常
    }
    curl_close($ch);
    return $handles;
}

