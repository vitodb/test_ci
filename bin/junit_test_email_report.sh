
junit_test_email_report() {
    echo "<br><br><br>"
    echo "<b>Unit Tests Results</b>"
    echo "<a href=https://buildmaster.fnal.gov/job/glideinwms_ci/${BUILD_NUMBER}/label_exp=${label_exp},label_exp2=${label_exp2}/testReport/(root)/>(Jenkins link)</a>"
    echo "<br><br>"
    echo "<table style=\"border: 1px solid black;border-collapse: collapse;\">"
    echo "<tr style=\"padding: 5px;text-align: center;\">"
    echo "<thead>"
    echo "<th style=\"background-color: #ffb300;padding: 8px;\"> TestClass     </th>"
    echo "<th style=\"background-color: #ffb300;padding: 8px;\"> duration (s)  </th>"
    echo "<th style=\"background-color: #ffb300;padding: 8px;\"> #tests        </th>"
    echo "<th style=\"background-color: #ffb300;padding: 8px;\"> #errors       </th>"
    echo "<th style=\"background-color: #ffb300;padding: 8px;\"> #failures     </th>"
    echo "</thead>"
    echo "<tbody>"
    REDCOLOR="#ff0000"
    GREENCOLOR="#00ff00"
    for f in $1/*.xml; do
        TESTCLASS=$(echo $f | sed  "s/.*-\(.*\)-.*/\1/")
        #echo "cat //testsuite/testcase/@name" | xmllint --shell $f
        NTESTS=$(echo "cat //testsuite/@tests" | xmllint --shell $f | grep -o -E "[0-9]{,10}")
        NERRORS=$(echo "cat //testsuite/@errors" | xmllint --shell $f | grep -o -E "[0-9]{,10}")
        ERRORCOLOR=$( ((NERRORS>0)) && echo ${REDCOLOR} || echo ${GREENCOLOR} )
        NFAILURES=$(echo "cat //testsuite/@failures" | xmllint --shell $f | grep -o -E "[0-9]{,10}")
        FAILURECOLOR=$( ((NFAILURES>0)) && echo ${REDCOLOR} || echo ${GREENCOLOR} )
        DURATION=$(echo "cat //testsuite/@time" | xmllint --shell $f | grep -o -E "[.0-9]{,10}")
        echo "<tr style=\"padding: 5px;text-align: center;\">"
        echo "<td style=\"border: 0px solid black;border-collapse: collapse;font-weight: bold;background-color: #00ccff;padding: 8px;\"> $TESTCLASS</td>"
        echo "<td style=\"border: 0px solid black;border-collapse: collapse;font-weight: bold;background-color: #00ff00;padding: 8px;\">$DURATION</td>"
        echo "<td style=\"border: 0px solid black;border-collapse: collapse;font-weight: bold;background-color: #00ff00;padding: 8px;\">$NTESTS</td>"
        echo "<td style=\"border: 0px solid black;border-collapse: collapse;font-weight: bold;background-color: ${ERRORCOLOR};padding: 8px;\">$NERRORS</td>"
        echo "<td style=\"border: 0px solid black;border-collapse: collapse;font-weight: bold;background-color: ${FAILURECOLOR};padding: 8px;\">$NFAILURES</td>"
        echo "</tr>"
    done
    echo "</tbody>"
    echo "</table>"
}


junit_test_email_report "$@" > junit_test_email.report
