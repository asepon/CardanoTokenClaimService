#!/bin/bash
clear
BUYBACK=0 # Change value to 1 if want to enable functionality
DELAY=2
ITERATE_DELAY=30
WORKINGFOLDER="/home/kawantest/cardano-my-node/tokens/faucet"
echo "WORKINGFOLDER :"$WORKINGFOLDER
cd $WORKINGFOLDER
NETWORK="--testnet-magic 1097911063"
MAGIC=testnet
myAddr=$(cat /home/kawantest/cardano-my-node/tokens/payment.addr)
paymentSignKeyPath=/home/kawantest/cardano-my-node/tokens/payment.skey
priceoftoken=3000000
tokenQty=75000
minUTXO=1400000
refundFee=210000
buybackFee=210000
#rate in lovelaces
buybackRate=30
buybackQuota=3570000
donateQty=15000000
minDelegate=10000000
minDelegateBuyback=100000000
minUTXObuybackRefund=1600000
myToken="0dfff08129a3cb0105536872c37d83c97299b56f4b31d5bd41397d78.74436c6f7665"
poolID=pool1vj86czk2m6n6xetvukzlj5ej8n7sly3yxt252r77al9xg4ka8sn
projectID=testnet30aQ3VbWyFLhZawJOamO5ybFmMq0aX8P
looping=1
log=$WORKINGFOLDER/log_file.log
utxo_valid=$WORKINGFOLDER/utxo_valid
utxo_refund=$WORKINGFOLDER/utxo_refund
utxo_donate=$WORKINGFOLDER/utxo_donate
utxo_buyback=$WORKINGFOLDER/utxo_buyback
utxo_consumed=$WORKINGFOLDER/utxo_consumed
temp_claim=$WORKINGFOLDER/temp_claim
temp_buyback=$WORKINGFOLDER/temp_buyback
claimed_list=$WORKINGFOLDER/claimed_list
unclaim_list=$WORKINGFOLDER/unclaim_list
buyback_list=$WORKINGFOLDER/buyback_list
fullUtxo=$WORKINGFOLDER/fullUtxo.out
balance=$WORKINGFOLDER/balance.out
txtmp=$WORKINGFOLDER/tx.tmp
txraw=$WORKINGFOLDER/tx.raw
txsigned=$WORKINGFOLDER/tx.signed
protocoljson=$WORKINGFOLDER/protocol.json
currentEpoch=0
rm $log
echo "Log File" >> $log
echo "-------------------" >> $log
echo "Process started at: $(date)" >> $log
echo "-------------------" >> $log
echo "" >> $log
echo "Log File"
echo "-------------------"
echo "Process started at: $(date)"
echo "-------------------"
sStart=$(date +%s)
cardano-cli query protocol-parameters $NETWORK --out-file $protocoljson

trap 'looping=0;wait' INT TERM
iterate=0
total_executed_buyback=0
while (( looping )); do
    echo "  -------------------">> $log
    echo "  -------------------"
    iterate=$(( ${iterate}+1 ))
    echo "  Iterate $iterate"
    echo "  Iterate $iterate">> $log

    seconds=$(($(date +%s)-$sStart))
    minutes=$(($seconds/60))
    hours=$(($minutes/60))
    days=$(($hours/24))
    pSecs=$(( $seconds-($minutes*60) ))
    pMins=$(( $minutes-($hours*60) ))
    pHours=$(( $hours-($days*24) ))
    echo "  Faucet have been running: $days day(s) $pHours hour(s) $pMins minute(s) $pSecs second(s)"
    echo "  -------------------"
    echo "  ---POPULATE UTXO and BUILD TX---"
    echo "  Faucet have been running: $days day(s) $pHours hour(s) $pMins minute(s) $pSecs second(s)">> $log
    echo "  -------------------">> $log
    echo "  ---POPULATE UTXO and BUILD TX---">> $log

    if [[ -f "$utxo_valid" ]]; then
         rm $utxo_valid
	    echo "  Delete file utxo_valid..."
	    echo "  Delete file utxo_valid..." >> $log
    fi

    if [[ -f "$utxo_refund" ]]; then
         rm $utxo_refund
	    echo "  Delete file utxo_refund..."
	    echo "  Delete file utxo_refund..." >> $log
    fi
    if [[ -f "$utxo_donate" ]]; then
        rm $utxo_donate
        echo "  Delete file utxo_donate..."
        echo "  Delete file utxo_donate..." >> $log
    fi
        if [[ -f "$utxo_buyback" ]]; then
        rm $utxo_buyback
        echo "  Delete file utxo_buyback..."
        echo "  Delete file utxo_buyback..." >> $log
    fi

    if [[ -f "$temp_claim" ]]; then
        rm $temp_claim
	    echo "  Delete file temp_claim..."
	    echo "  Delete file temp_claim..." >> $log
    fi

    if [[ -f "$temp_buyback" ]]; then
        rm $temp_buyback
	    echo "  Delete file temp_buyback..."
	    echo "  Delete file temp_buyback..." >> $log
    fi

    if [[ -f "$txtmp" ]] || [[ -f "$txraw" ]]; then
        rm tx.*
	    echo "  Delete file tx files..."
	    echo "  Delete file tx files..." >> $log
    fi

    tx_in=""
    txout_change=""
    txout_valid=""
    txout_refund=""
    txout_buyback=""
    total_minUTXO=0
    total_balance=0
    total_buyback=0
    total_buybackFee=0
    total_refundFee=0
    total_tokenSold=0
    total_tokenAmount=0
    total_tokenBuyback=0
    total_refundVal=0
    total_donation=0
    cardano-cli query utxo --address $myAddr $NETWORK > $fullUtxo
    tail -n +3 ${fullUtxo} | sort -k3 -nr  > $balance
    echo "  ---BALANCE TX IN---"
    echo "  ---BALANCE TX IN---" >> $log
    cat ${balance} >> $log
    cat ${balance}

    txcnt=$(cat ${balance} | wc -l)
    echo "  tx-in-count :"$txcnt
    echo "  tx-in-count :"$txcnt >> $log
    if [[ $txcnt -lt 2 ]]
    then 
        echo "      ###---There is no new valid/refund/donation transaction input..." >> $log
        echo "      ###---There is no new valid/refund/donation transaction input..."
        echo "      Waiting next iterate..." >> $log
        echo "      Waiting next iterate..." 
    else
        iUtxo=0
        total_buyback_one_iterate=0
        while read -r utxo; do
            sleep $DELAY
            iUtxo=$(( ${iUtxo}+1 ))
            currentEpoch=$(cardano-cli query tip $NETWORK | jq -r '.epoch')
            echo "          ITERATE ${iterate} UTXO ${iUtxo} detected"
            echo "          -----------------------------------------"
            echo "          ITERATE ${iterate} UTXO ${iUtxo} detected" >> $log
            echo "          -----------------------------------------" >> $log
            token=$(awk '{ print $7}' <<< "${utxo}")
            exTokenExist=$(awk '{ print $6 }' <<< "${utxo}")
            #IF UTXO not have token and the token is not the token that will be delivered.        
            if [[ ${exTokenExist} != "TxOutDatumNone" ]] && [[ ${token} != ${myToken} ]]
                then
                echo "          This utxo detected has tokens...">> $log
                echo "          Skipping this utxo...">> $log
                echo "          This utxo detected has tokens..."
                echo "          Skipping this utxo..."
            else
                tx_hash=$(awk '{ print $1 }' <<< "${utxo}")
                idx=$(awk '{ print $2 }' <<< "${utxo}")
                utxo_balance=$(awk '{ print $3 }' <<< "${utxo}")

                #IF UTXO has the same token with service,
                #Process the buyback service
                
                if [[ ${token} = ${myToken} ]]
                then
                    echo "              myToken is detected"
                    echo "              myToken is detected" >> $log
                    in_addr=$(curl -H 'project_id: '${projectID} \
                            https://cardano-${MAGIC}.blockfrost.io/api/v0/txs/${tx_hash}/utxos \
                            | jq '.inputs' | jq '.[0]' | jq '.address' | sed 's/^.//;s/.$//')
                    echo "              in_addr :"$in_addr
                    echo "              in_addr :"$in_addr >> $log
                    echo "              ----Processing BUYBACK Service ----"
                    echo "              ----Processing BUYBACK Service ----" >> $log
                    tokenAmount=$(awk '{ print $6}' <<< "${utxo}")
                    
                    if [[ ${BUYBACK} -eq 1 ]]
                    then 
                        echo "                  Buyback enable ="$BUYBACK
                        echo "                  Buyback enable ="$BUYBACK >> $log

                        #IF BUYBACK=0 and UTXO address the same with service address, Collect token amount, write tx_out for change
                        if [[ ${in_addr} = ${myAddr} ]] 
                        then 
                            echo "                      Get Buyback Service ADA, Token balance, build tx-in-out-change"
                            echo "                      Get Buyback Service ADA, Token balance, build tx-in-out-change" >> $log
                            echo "                      [v]Service Addr $myAddr met the utxo address"
                            echo "                      [v]Service Addr $myAddr met the service utxo hash" >> $log
                            balanceLiquidity=${utxo_balance}
                            total_balance=$(($total_balance+$utxo_balance))
                            total_tokenAmount=$(($total_tokenAmount+$tokenAmount))
                            #this txout change just for drafting tx
                            tx_in="--tx-in ${tx_hash}#${idx} "${tx_in}
                            txout_change="--tx-out ${myAddr}+${utxo_balance}+'${tokenAmount} ${myToken}'"
                        #Else Process buyback
                        else
                            echo "                      [x]NOT Service Addr $myAddr met utxo address $in_addr"
                            echo "                      [x]NOT Service Addr $myAddr met utxo address $in_addr" >> $log
                            echo "                      Validating and build txout buyback..."
                            echo "                      Validating and build txout buyback..." >> $log 

                            in_stake_addr=$(curl -H 'project_id: '${projectID} \
                                https://cardano-${MAGIC}.blockfrost.io/api/v0/addresses/${in_addr} \
                                | jq '.stake_address' | sed 's/^.//;s/.$//')
                            echo "                      stake_addr :"$in_stake_addr
                            echo "                      stake_addr :"$in_stake_addr >> $log
                            delegInfo=($(curl -H 'project_id: '${projectID} \
                                https://cardano-${MAGIC}.blockfrost.io/api/v0/accounts/${in_stake_addr}/delegations \
                                | jq 'last | .active_epoch,.pool_id'))
                            amountActive=$(curl -H 'project_id: '${projectID} \
                                https://cardano-${MAGIC}.blockfrost.io/api/v0/accounts/${in_stake_addr} \
                                | jq '.controlled_amount' | sed 's/^.//;s/.$//')

                            echo "                      ----VALIDATING DELEGATION INFORMATION----"
                            echo "                      ----VALIDATING DELEGATION INFORMATION----">> $log
                            activeEpoch=${delegInfo[0]}
                            delegPool=$( echo ${delegInfo[1]} | sed 's/.//;s/.$//' )

                            condition=0
                            if [ $(( ${amountActive} )) -gt $(( ${minDelegateBuyback}-1 )) ]
                            then 
                                echo "                          [v]1.amount minimal active stake met $(( ${minDelegateBuyback}-1 ))"
                                echo "                          [v]1.amount minimal active stake met $(( ${minDelegateBuyback}-1 ))" >> $log
                                condition=$(( $condition + 1 ))
                            else 
                                echo "                          [x]1.amount minimal active stake ${amountActive} NOT met "$(( ${minDelegateBuyback}-1 ))
                                echo "                          [x]1.amount minimal active stake ${amountActive} NOT met "$(( ${minDelegateBuyback}-1 )) >> $log
                            fi

                            if [ $(( ${activeEpoch} )) -lt $(( ${currentEpoch} )) ]
                            then 
                                echo "                          [v]2.Active epoch met ${currentEpoch}"
                                echo "                          [v]2.Active epoch met ${currentEpoch}" >> $log
                                condition=$(( $condition + 1 ))
                            else 
                                echo "                          [x]2.Active epoch ${currentEpoch} not met, comeback later at epoch "${activeEpoch}
                                echo "                          [x]2.Active epoch ${currentEpoch} not met, comeback later at epoch "${activeEpoch} >> $log
                            fi 
                            
                            if [[ ${delegPool} = ${poolID} ]] 
                            then 
                                echo "                          [v]3.Pool Valid "$poolID
                                echo "                          [v]3.Pool Valid "$poolID >> $log
                                condition=$(( $condition + 1 ))
                            else
                                echo "                          [x]3.Pool $delegPool Invalid, please delegate to "$poolID
                                echo "                          [x]3.Pool $delegPool Invalid, please delegate to "$poolID >> $log
                            fi
                            
                            #check if UTXO balance met the min ADA for refund, if not met will skip UTXO and refund with another service
                            if [[ $utxo_balance -gt $(($minUTXObuybackRefund-1)) ]]
                            then 
                                echo "                          [v]Balance met minimum ADA $minUTXObuybackRefund for refund"
                                echo "                          [v]Balance met minimum ADA $minUTXObuybackRefund $ for refund" >> $log
                            else 
                                echo "                          [x]NOT Balance $utxo_balance met minimum $minUTXObuybackRefund ADA for refund"
                                echo "                          [x]NOT Balance $utxo_balance met minimum $minUTXObuybackRefund ADA for refund" >> $log
                            fi 
                            
                            #check remaining buyback quota
                            buybackQuotaLeft=$(($buybackQuota-$total_buyback_one_iterate-$total_executed_buyback))
                            echo buybackQuotaLeft: $buybackQuotaLeft
                            echo buybackQuotaLeft: $buybackQuotaLeft  >> $log
                            if [[ $tokenAmount -lt $buybackQuotaLeft ]]
                            then
                                echo "                          [v]Token amount $tokenAmount sufficient buyback Quota "
                                echo "                          [v]Token amount $tokenAmount sufficient buyback Quota " >> $log
                            else 
                                echo "                          [x]NOT Token amount $tokenAmount sufficient buyback Quota $buybackQuotaLeft"
                                echo "                          [x]NOT Token amount $tokenAmount sufficient buyback Quota $buybackQuotaLeft" >> $log
                            fi

                            #check UTXO address if already buyback this epoch or this batch
                            isBuyback=$( grep ${in_stake_addr} $buyback_list$currentEpoch | awk '{ print $1 }' )
                            isBuybackTemp=$( grep ${in_stake_addr} $temp_buyback | awk '{ print $1 }' )
                            echo "                          isBuyback :"$isBuyback
                            echo "                          isBuyback :"$isBuyback >> $log
                            echo "                          isBuybackTemp :"$isBuybackTemp
                            echo "                          isBuybackTemp :"$isBuybackTemp >> $log
                            if [[ $isBuyback ]] || [[ $isBuybackTemp ]]
                            then 
                                echo "                          [x]Epoch $currentEpoch stake address $in_stake_addr already buyback "
                                echo "                          [x]Epoch $currentEpoch stake address $in_stake_addr already buyback " >> $log
                            else 
                                echo "                          [v]Epoch $currentEpoch stake address $in_stake_addr NOT buyback "
                                echo "                          [v]Epoch $currentEpoch stake address $in_stake_addr NOT buyback " >> $log                                 
                            fi

                            #Will refund if all delegation condition not met
                            echo "                      CONDITION :" $condition
                            echo "                      CONDITION :" $condition >> $log
                            if [[ $condition -eq 3 ]] &&  [[ $buybackQuotaLeft -gt 0 ]] && [[ ! $isBuyback ]] && [[ ! $isBuybackTemp ]]
                            then
                                echo "                          All Delegation condition met">> $log
                                echo "                          Process txout buyback send asset...">> $log
                                echo "                          All Delegation condition met"
                                echo "                          Process txout buyback send asset..."
                                
                                echo "${tx_hash}#${idx} ${utxo_balance} ${in_addr}" >> $utxo_buyback
                                tx_in="--tx-in ${tx_hash}#${idx} "${tx_in}

                                #set max buyback qty based on amount active stake
                                if [[ $amountActive -gt 49999000000 ]]
                                then 
                                    maxBuybackQty=500000
                                elif [[ $amountActive -gt 19999000000 ]]
                                then 
                                    maxBuybackQty=300000
                                elif [[ $amountActive -gt 9999000000 ]]
                                then 
                                    maxBuybackQty=200000
                                elif [[ $amountActive -gt 4999000000 ]]
                                then 
                                    maxBuybackQty=150000
                                elif [[ $amountActive -gt 999000000 ]]
                                then 
                                    maxBuybackQty=125000
                                elif [[ $amountActive -gt 499000000 ]]
                                then 
                                    maxBuybackQty=100000
                                else 
                                    maxBuybackQty=75000
                                fi
                                
                                #Check if consume all token or partial
                                if [[ $tokenAmount -lt $buybackQuotaLeft ]] && [[ $tokenAmount -lt $maxBuybackQty ]]
                                then 
                                    echo "                          Buyback all token"
                                    echo "                          Buyback all token" >> $log 
                                    total_buyback_one_iterate=$(($total_buyback_one_iterate+$tokenAmount))
                                    total_tokenBuyback=$(($total_tokenBuyback+$tokenAmount))
                                    amount_tx_buyback=$(($buybackRate*$tokenAmount-$buybackFee+$utxo_balance))
                                    total_balance=$(($total_balance+$utxo_balance))
                                    total_buyback=$(($total_buyback+$amount_tx_buyback))
                                    total_buybackFee=$(($total_buybackFee+$buybackFee))
                                    txout_buyback="--tx-out ${in_addr}+$((${amount_tx_buyback})) "$txout_buyback
                                elif [[ $tokenAmount -gt $maxBuybackQty-1 ]] && [[ $maxBuybackQty -lt $buybackQuotaLeft ]]
                                then 
                                    echo "                          Seller send more than MAX Buyback, give change"
                                    echo "                          Seller send more than MAX Buyback, give change" >> $log
                                    tokenAmountChange=$(($tokenAmount-$maxBuybackQty))
                                    total_buyback_one_iterate=$(($total_buyback_one_iterate+$maxBuybackQty))
                                    total_tokenBuyback=$(($total_tokenBuyback+$maxBuybackQty))
                                    amount_tx_buyback=$(($buybackRate*$maxBuybackQty-$buybackFee+$utxo_balance))
                                    total_balance=$(($total_balance+$utxo_balance))
                                    total_buyback=$(($total_buyback+$amount_tx_buyback))
                                    total_buybackFee=$(($total_buybackFee+$buybackFee))
                                    txout_buyback="--tx-out ${in_addr}+$((${amount_tx_buyback}))+'${tokenAmountChange} ${myToken}' "$txout_buyback
                                else 
                                    echo "                          More than Quota left, give change to seller"
                                    echo "                          More than Quota left, give change to seller" >> $log
                                    #update token amount to fit the quota buyback left
                                    tokenAmountChange=$(($tokenAmount-$buybackQuotaLeft))
                                    total_buyback_one_iterate=$(($total_buyback_one_iterate+$buybackQuotaLeft))
                                    total_tokenBuyback=$(($total_tokenBuyback+$buybackQuotaLeft))
                                    amount_tx_buyback=$(($buybackRate*$buybackQuotaLeft-$buybackFee+$utxo_balance))
                                    total_balance=$(($total_balance+$utxo_balance))
                                    total_buyback=$(($total_buyback+$amount_tx_buyback))
                                    total_buybackFee=$(($total_buybackFee+$buybackFee))
                                    txout_buyback="--tx-out ${in_addr}+$((${amount_tx_buyback}))+'${tokenAmountChange} ${myToken}' "$txout_buyback
                                fi
                                #put in stake address to temp list buyback
                                echo $in_stake_addr >> $temp_buyback
                            elif [[ $utxo_balance -gt $(($minUTXObuybackRefund-1)) ]] && [[ $tokenAmount -lt $buybackQuotaLeft ]]
                            then
                                echo "                          NOT All Delegation condition met!">> $log
                                echo "                          Process txout refund buyback...">> $log
                                echo "                          NOT All Delegation condition met!"
                                echo "                          Process txout refund buyback..."
                                echo "${tx_hash}#${idx} ${utxo_balance} ${in_addr}" >> $utxo_refund
                                tx_in="--tx-in ${tx_hash}#${idx} "${tx_in}
                                refundValue=$(($utxo_balance))
                                total_balance=$(($total_balance+$utxo_balance))
                                total_refundVal=$(($total_refundVal+$refundValue))
                                txout_refund="--tx-out ${in_addr}+${refundValue}+'${tokenAmount} ${myToken}' "$txout_refund
                                total_refundFee=$(($total_refundFee+$refundFee))
                            else 
                                echo "                          Will refund with another service"
                                echo "                          Will refund with another service" >> $log
                            fi
                            echo "                      ----END VALIDATING UTXO DELEGATION INFORMATION----">> $log
                            echo "                      ----END VALIDATING UTXO DELEGATION INFORMATION----"
                            sleep $DELAY

                        fi
                    elif [[ ${in_addr} = ${myAddr} ]] 
                    then 
                        echo "                  Buyback NOT enable ="$BUYBACK
                        echo "                  Buyback NOT enable ="$BUYBACK >> $log
                        echo "                  Get Claim Service ADA, Token Balance and build tx-in-out_change"
                        echo "                  Get Claim Service ADA, Token Balance and build tx-in-out_change" >> $log
                        #this txout change just for drafting tx
                        tx_in="--tx-in ${tx_hash}#${idx} "${tx_in}
                        total_balance=$(($total_balance+$utxo_balance))
                        total_tokenAmount=$(($total_tokenAmount+$tokenAmount))
                        txout_change="--tx-out ${myAddr}+$(( ${utxo_balance} ))+'${tokenAmount} ${myToken}'"
                    else 
                        echo "                  Buyback NOT enable ="$BUYBACK
                        echo "                  Buyback NOT enable ="$BUYBACK >> $log
                        echo "                  NOT Service UTXO, Skip UTXO..."
                        echo "                  NOT Service UTXO, Skip UTXO..." >> $log
                    fi 

                    echo "              ----END Processing BUYBACK Service ----"
                    echo "              ----END Processing BUYBACK Service ----" >> $log
                    
                #ELSEIF utxo have the exact balance for the price of token,
                #Process the claim service              
                elif [ ${utxo_balance} -eq ${priceoftoken} ] && [[ ${BUYBACK} -eq 0 ]];
                then
                    echo "              -----Processing CLAIM Service-----"
                    echo "              -----Processing CLAIM Service-----">> $log
                    in_addr=$(curl -H 'project_id: '${projectID} \
                        https://cardano-${MAGIC}.blockfrost.io/api/v0/txs/${tx_hash}/utxos \
                        | jq '.inputs' | jq '.[0]' | jq '.address' | sed 's/^.//;s/.$//')
                    echo "              in_addr :"$in_addr
                    echo "              in_addr :"$in_addr >> $log
                    in_stake_addr=$(curl -H 'project_id: '${projectID} \
                        https://cardano-${MAGIC}.blockfrost.io/api/v0/addresses/${in_addr} \
                        | jq '.stake_address' | sed 's/^.//;s/.$//')
                    echo "              stake_addr :"$in_stake_addr
                    echo "              stake_addr :"$in_stake_addr >> $log
                    delegInfo=($(curl -H 'project_id: '${projectID} \
                        https://cardano-${MAGIC}.blockfrost.io/api/v0/accounts/${in_stake_addr}/delegations \
                        | jq 'last | .active_epoch,.pool_id'))
                    amountActive=$(curl -H 'project_id: '${projectID} \
	                    https://cardano-${MAGIC}.blockfrost.io/api/v0/accounts/${in_stake_addr} \
	                    | jq '.controlled_amount' | sed 's/^.//;s/.$//')
                    
                    activeEpoch=${delegInfo[0]}
                    delegPool=$( echo ${delegInfo[1]} | sed 's/.//;s/.$//' )
                    echo "              amountActive :"$amountActive" VS "$(( ${minDelegate}-1 ))>> $log
                    echo "              activeEpoch  :"$activeEpoch" VS "$(( ${currentEpoch} ))>> $log
                    echo "              delegPool    :"$delegPool" VS "$poolID>> $log
                    echo "              amountActive :"$amountActive" VS "$(( ${minDelegate}-1 ))
                    echo "              activeEpoch  :"$activeEpoch" VS "$(( ${currentEpoch} ))
                    echo "              delegPool    :"$delegPool" VS "$poolID
                    sleep $DELAY
                    #Will refund if the stake address not delegate with specific pool for atleast 2 epoch with min active Delegated.
                    if [[ ${delegPool} = ${poolID} ]] && [ $(( ${activeEpoch} )) -lt $(( ${currentEpoch} )) ] && [ $(( ${amountActive} )) -gt $(( ${minDelegate}-1 )) ]
                    then
                        echo "                  Delegated to KAWAN">> $log
                        echo "                  Process txout send asset...">> $log
                        echo "                  Delegated to KAWAN"
                        echo "                  Process txout send asset..."
                        CMD="cardano-cli transaction calculate-min-required-utxo \
                            --alonzo-era \
                            --tx-out ${in_addr}+0'${tokenQty} ${myToken}' \
                            --protocol-params-file $protocoljson | awk '{ print $1 }'"
                        echo "                  => "$CMD >> $log
                        echo "                  => "$CMD
                        minUTXO=$(eval $CMD | awk '{ print $2 }')
                        echo "                  utxo balance equall price detected"
                        echo "                  utxo balance equall price detected" >> $log
                        unclaimQty=0
                        unclaimAddr=""
                        #cek stakeaddress from unclaim if found, add the qty token
                        unclaimAddr=$( grep ${in_stake_addr} $unclaim_list | awk '{ print $1 }' )
                        isClaimed=$( grep ${in_stake_addr} $claimed_list | awk '{ print $1 }' )
                        echo "                  unclaimAddr :"$unclaimAddr
                        echo "                  unclaimAddr :"$unclaimAddr >> $log
                        echo "                  isClaimed :"$isClaimed
                        echo "                  isClaimed :"$isClaimed >> $log
                        if [[ ${unclaimAddr} ]] && [[ -z $isClaimed ]]
                        then 
                            unclaimQty=$( grep ${in_stake_addr} $unclaim_list | awk '{ print $2 }' )
                            echo "                      This stake address have unclaim token " $unclaimQty
                            echo "                      This stake address have unclaim token " $unclaimQty >> $log
                            echo $unclaimAddr >> $temp_claim
                        fi
                        total_balance=$(($total_balance+$utxo_balance))
                        total_minUTXO=$(($total_minUTXO+$minUTXO))
                        total_tokenSold=$(($total_tokenSold+${tokenQty}+${unclaimQty}))
                        total_claim_token=$(( ${tokenQty}+${unclaimQty} ))
                        echo "${tx_hash}#${idx} ${utxo_balance} ${in_addr}" >> $utxo_valid
                        tx_in="--tx-in ${tx_hash}#${idx} "${tx_in}
                        txout_valid="--tx-out ${in_addr}+${minUTXO}+'${total_claim_token} ${myToken}' "$txout_valid
                    else
                        echo "                  This address not delegate to KAWAN">> $log
                        echo "                  Process txout refund...">> $log
                        echo "                  This address not delegate to KAWAN"
                        echo "                  Process txout refund..."
                        echo "${tx_hash}#${idx} ${utxo_balance} ${in_addr}" >> $utxo_refund
                        total_balance=$(($total_balance+$utxo_balance))
                        refundValue=$(($utxo_balance-$refundFee))
                        total_refundVal=$(($total_refundVal+$refundValue))
                        total_refundFee=$(($total_refundFee+$refundFee))
                        tx_in="--tx-in ${tx_hash}#${idx} "${tx_in}
                        txout_refund="--tx-out ${in_addr}+${refundValue} "$txout_refund
                    fi
                    echo "              -----END Processing CLAIM Service-----"
                    echo "              -----END Processing CLAIM Service-----">> $log
                    sleep $DELAY
                elif [ ${utxo_balance} -lt ${donateQty} ] && [[ ${BUYBACK} -eq 0 ]];
                then
                    in_addr=$(curl -H 'project_id: '${projectID} \
                            https://cardano-${MAGIC}.blockfrost.io/api/v0/txs/${tx_hash}/utxos \
                            | jq '.inputs' | jq '.[0]' | jq '.address' | sed 's/^.//;s/.$//')
                    echo "              ----Processing Donating TX----"
                    echo "              ----Processing Donating TX----" >> $log
                    echo "${tx_hash}#${idx} ${utxo_balance} ${in_addr}" >> $utxo_donate
                    total_balance=$(($total_balance+$utxo_balance))
                    tx_in="--tx-in ${tx_hash}#${idx} "${tx_in}
                    total_donation=$(($total_donation+$utxo_balance))
                    echo "              ----END Processing Donating TX----"
                    echo "              ----END Processing Donating TX----" >> $log
                elif [[ ${BUYBACK} -eq 0 ]];
                then
                    in_addr=$(curl -H 'project_id: '${projectID} \
                            https://cardano-${MAGIC}.blockfrost.io/api/v0/txs/${tx_hash}/utxos \
                            | jq '.inputs' | jq '.[0]' | jq '.address' | sed 's/^.//;s/.$//')
                    echo "              ----Processing Claim Refund----"
                    echo "              ----Processing Claim Refund----" >> $log
                    echo "${tx_hash}#${idx} ${utxo_balance} ${in_addr}" >> $utxo_refund
                    total_balance=$(($total_balance+$utxo_balance))
                    refundValue=$(($utxo_balance-$refundFee))
                    total_refundVal=$(($total_refundVal+$refundValue))
                    total_refundFee=$(($total_refundFee+$refundFee))
                    tx_in="--tx-in ${tx_hash}#${idx} "${tx_in}
                    txout_refund="--tx-out ${in_addr}+${refundValue} "$txout_refund
                    echo "              ----END Processing Claim Refund----"
                    echo "              ----END Processing Claim Refund----" >> $log
                fi
            fi

        done < ${balance}
        echo "      ###------DRAFT TX------###" >> $log
        echo "          tx_in           ==> "${tx_in} >> $log
        echo "          txout_valid     ==> "$txout_valid >> $log
        echo "          txout_buyback   ==> "$txout_buyback >> $log
        echo "          txout_refund    ==> "$txout_refund >> $log
        echo "          txout-change    ==> "${txout_change} >> $log
        echo "      ###------DRAFT TX------###"
        echo "          tx_in           ==> "${tx_in}
        echo "          txout_valid     ==> "$txout_valid
        echo "          txout_buyback   ==> "$txout_buyback
        echo "          txout_refund    ==> "$txout_refund
        echo "          txout-change    ==> "${txout_change}        
        
        CMD="cardano-cli transaction build-raw \
            ${tx_in} \
            ${txout_valid} \
            ${txout_buyback} \
            ${txout_refund} \
            ${txout_change} \
            --babbage-era \
            --invalid-hereafter $(( ${currentSlot} + 10000)) \
            --fee 0 \
            --out-file ${txtmp}"
        echo "          => "$CMD >> $log
        echo "          => "$CMD
        eval $CMD

        echo "      ###------CALC FEE------###" >> $log
        echo "      ###------CALC FEE------###"
        fee=$(cardano-cli transaction calculate-min-fee \
            --tx-body-file $txtmp \
            --tx-in-count $txcnt \
            --tx-out-count $txcnt \
            $NETWORK \
            --witness-count 1 \
            --byron-witness-count 0 \
            --protocol-params-file $protocoljson | awk '{ print $1 }')
        eval $CMD

        txOut=$((${total_balance}-${total_buyback}-${fee}-${total_minUTXO}-${total_refundVal}))
        tokenRemain=$(($total_tokenAmount+$total_tokenBuyback-$total_tokenSold))

        if [[ ${total_buybackFee} -eq 0 ]] && [[ ${total_buyback} -eq 0 ]] && 
            [[ $total_minUTXO -eq 0 ]] && [[ $total_refundFee -eq 0 ]] && 
            [[ $total_refundVal -eq 0 ]] && [[ $total_donation -eq 0 ]] && 
            [[ $tokenRemain -eq $total_tokenAmount ]] && [[ ${total_balance} -eq $txOut+$fee ]]
        then
            echo "      ###---There is no new valid/refund/donation transaction input..." >> $log
            echo "      ###---There is no new valid/refund/donation transaction input..."
        else
            echo "      INPUT ADA-----------------" >> $log
            echo "          total_balance         : "${total_balance} >> $log
            echo "      OUTPUT ADA----------------" >> $log
            echo "          fee                   : "${fee} >> $log
            echo "          total_minUTXO         : "${total_minUTXO} >> $log
            echo "          total_buyback         : "${total_buyback} >> $log
            echo "          total_buybackFee      : "${total_buybackFee} >> $log
            echo "          total_refundFee       : "${total_refundFee} >> $log
            echo "          total_refundVal       : "${total_refundVal} >> $log
            echo "          total_donation        : "$total_donation >> $log
            echo "          txOut                 : "$txOut >> $log
            echo "      INPUT TOKENS--------------" >> $log
            echo "          total_tokenAmount     : "$total_tokenAmount >> $log
            echo "          total_tokenBuyback    : "$total_tokenBuyback >> $log
            echo "      OUTPUT TOKENS-------------" >> $log
            echo "          total_tokenSold       : "$total_tokenSold >> $log
            echo "          tokenRemain           : "$tokenRemain >> $log
            
            echo "      INPUT ADA-----------------" 
            echo "          total_balance         : "${total_balance}
            echo "      OUTPUT ADA----------------" 
            echo "          fee                   : "${fee}
            echo "          total_minUTXO         : "${total_minUTXO}
            echo "          total_buyback         : "${total_buyback}
            echo "          total_buybackFee      : "${total_buybackFee}
            echo "          total_refundFee       : "${total_refundFee}
            echo "          total_refundVal       : "${total_refundVal}
            echo "          total_donation        : "$total_donation
            echo "          txOut                 : "$txOut
            echo "      INPUT TOKENS--------------" 
            echo "          total_tokenAmount     : "$total_tokenAmount
            echo "          total_tokenBuyback    : "$total_tokenBuyback
            echo "      OUTPUT TOKENS-------------" 
            echo "          total_tokenSold       : "$total_tokenSold
            echo "          tokenRemain           : "$tokenRemain
            echo ""
            currentSlot=$(cardano-cli query tip $NETWORK | jq -r '.slot')
            echo "      ###------BUILD TX------###" >> $log
            echo "      ###------BUILD TX------###"
            CMD="cardano-cli transaction build-raw \
                --babbage-era \
                ${tx_in} \
                ${txout_buyback} \
                ${txout_valid} \
                ${txout_refund} \
                --tx-out ${myAddr}+${txOut}'+${tokenRemain} ${myToken}'  \
                --invalid-hereafter $(( ${currentSlot} + 10000)) \
                --fee $fee \
                --out-file ${txraw}"
            #--tx-out ${myAddr}+${txOut}'+${tokenRemain} ${myToken}'  \
            
            echo "      => "$CMD >> $log
            echo "      => "$CMD
            eval $CMD >> $log
            CMD="cardano-cli transaction sign \
                --tx-body-file ${txraw} \
                --signing-key-file ${paymentSignKeyPath} \
                $NETWORK \
                --out-file ${txsigned}"
            echo "      => "$CMD >> $log
            echo "      => "$CMD
            eval $CMD >> $log

            CMD="cardano-cli transaction submit \
                --tx-file ${txsigned} ${NETWORK}"
            echo "      => "$CMD >> $log
            echo "      => "$CMD
            eval $CMD | tee -a $log
            
            if [[ $( tail -n 1 $log ) = "Transaction successfully submitted." ]] 
            then 
                if [[ -f temp_claim ]];
                then 
                    echo '      append temp_claim to claimed_list'
                    echo '      append temp_claim to claimed_list' >> $log
                    echo $( cat temp_claim ) >> $claimed_list
                fi 

                if [[ -f temp_buyback ]];
                then 
                    echo '      append temp_buyback to buyback_list'
                    echo '      append temp_buyback to buyback_list' >> $log
                    echo $( cat temp_buyback ) >> $buyback_list$currentEpoch
                fi

                #write history tx-in, and address related to it
                if [[ -f utxo_valid ]] || [[ -f utxo_buyback ]] || [[ -f utxo_refund ]] || [[ -f utxo_donate ]]
                then 
                    echo "ITERATE $iterate" >> $utxo_consumed
                    if [[ -f utxo_valid ]];
                    then 
                        echo '      append utxo_valid to utxo_consumed'
                        echo '      append utxo_valid to utxo_consumed' >> $log
                        echo "----utxo_valid----" >> $utxo_consumed
                        echo $( cat utxo_valid ) >> $utxo_consumed
                    fi

                    if [[ -f utxo_buyback ]];
                    then 
                        total_executed_buyback=$(($total_executed_buyback+$total_tokenBuyback))
                        echo '      append utxo_buyback to utxo_consumed'
                        echo '      append utxo_buyback to utxo_consumed' >> $log
                        echo "      buybackQuota           : "$buybackQuota
                        echo "      buybackQuota           : "$buybackQuota >> $log
                        echo "      total_executed_buyback : "$total_executed_buyback
                        echo "      total_executed_buyback : "$total_executed_buyback >> $log
                        echo "      remainingQuota         : "$(($buybackQuota-$total_executed_buyback))
                        echo "      remainingQuota         : "$(($buybackQuota-$total_executed_buyback)) >> $log

                        echo "----utxo_buyback----" >> $utxo_consumed
                        echo $( cat utxo_buyback ) >> $utxo_consumed

                        if [[ $(($buybackQuota-$total_executed_buyback)) -lt 1 ]]
                        then 
                            echo "Buyback Quota $buybackQuota MET"
                            echo 'Turn off buyback Service'
                            echo "Buyback Quota $buybackQuota MET" >> $log
                            echo 'Turn off buyback Service' >> $log
                            exit
                        fi
                    fi

                    if [[ -f utxo_refund ]];
                    then 
                        echo '      append utxo_refund to utxo_consumed'
                        echo '      append utxo_refund to utxo_consumed' >> $log
                        echo "----utxo_refund----" >> $utxo_consumed
                        echo $( cat utxo_refund ) >> $utxo_consumed
                    fi

                    if [[ -f utxo_donate ]];
                    then 
                        echo '      append utxo_donate to utxo_consumed'
                        echo '      append utxo_donate to utxo_consumed' >> $log
                        echo "----utxo_donate----" >> $utxo_consumed
                        echo $( cat utxo_donate ) >> $utxo_consumed
                    fi

                fi
            fi
        fi
    fi
    sleep $ITERATE_DELAY
done
