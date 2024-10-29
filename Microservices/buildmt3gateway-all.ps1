Param(
    $acrname = "kizmain",    
    $imageprefix = "mt3gateway"
)
$acrname = $acrname + ".azurecr.io";
$imagename = "$($imageprefix)-gateway"
# docker build -t "$($acrname)/$($imagename):latest" --file ./Gateway/MT3Gateway-Gateway/Dockerfile .
# docker push "$($acrname)/$($imagename):latest"
# $imagename = "$($imageprefix)-status"
# docker build -t "$($acrname)/$($imagename):latest" --file ./Gateway/MT3Gateway-Status/Dockerfile .
# docker push "$($acrname)/$($imagename):latest"

$imagename = "$($imageprefix)-web"
docker build -t "$($acrname)/$($imagename):latest" --file ./Gateway/MT3Gateway-Web/Dockerfile .
docker push "$($acrname)/$($imagename):latest"
# for (($i = 1); $i -lt 6; $i++) {
#     $step = $i
#     $imagename = "mt3gateway-step$($step)"
#     docker build -t "$($acrname)/$($imagename):latest" --file "./Gateway/MT3Gateway-Step$($step)/Dockerfile" .
#     docker push "$($acrname)/$($imagename):latest"
# }
