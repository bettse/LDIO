# LDIO
Lego Dimensions OS X app



## Commands


### Command format

`UULLCMCOP1P2..PNCK`

 * UU = 'U' literal
 * LL = length
 * CM = command
 * CO = corrolation id (returned in response)
 * P1, P2, .., PN: Parameters
 * CK: checksum of all bytes before it

### Response format

`UULLCOP1P2..PNCK`

 * UU = 'U' literal
 * LL = Length
 * CO = corrolation id
 * P1, P2, .., PN: output data
 * CK: checksum of all bytes before it

### Update format

`VVLLPPXX XXDRTTTT TTTTTTTT TTCK`
 * VV = 'V' literal
 * LL = length
 * PP = Platform (1 = center, 2 = left, 3 = right)
 * XX = ??
 * DR = direction (0 = arriving, 1 = departing)
 * TTTTTTTTTTTTTT = Tag UID
 * CK = checksum of ALL bytes before it



### 0xB0 Activate

 * parameter: 13 byte constant: `28632920 4c45474f 20323031 34`

### 0xB1

 * 8 byte parameter, 8 byte response

### 0xB3

### 0xC0 Light

 * ex: Center light on white: `55 06 c0 02 01 ff 6e 18 a3`

 * P1: platform (0 = all, 1 = center, 2 = left, 3 = right)
 * P2 = Red component
 * P3 = Green component
 * P4 = Blue componant

### 0xC2 Light

 * ex: `55 08 c2 11 02 10 01 00 00 16 59`

### 0xC6 Light

 * ex: Quickly fade left side blue: `55 14 c6 05 01 03 01 00 00 00 01 10 01 00 00 16 01 03 01 00 00 00 66`


