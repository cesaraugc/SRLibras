package cn.jingedawang.bluetoothdemo;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.TimeUnit;

public class MainActivity extends Activity {

    private static final int REQUEST_ENABLE_BT = 1;

    private TextView txtIsConnected;
    private EditText edtReceivedMessage;
    private EditText edtSentMessage;
    private EditText edtSendMessage;
    private Button btnSend;
    private Button btnClear;
    private Button btnPairedDevices;

    private BluetoothAdapter mBluetoothAdapter;
    private ConnectedThread mConnectedThread;
    List<Byte> valoresLidos = new ArrayList<Byte>();
    long startTime;
    long endTime;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        txtIsConnected = (TextView) findViewById(R.id.txtIsConnected);
        edtReceivedMessage = (EditText) findViewById(R.id.edtReceivedMessage);
        edtSentMessage = (EditText) findViewById(R.id.edtSentMessage);
        edtSendMessage = (EditText) findViewById(R.id.edtSendMessage);
        btnSend = (Button) findViewById(R.id.btnSend);
        btnPairedDevices = (Button) findViewById(R.id.btnPairedDevices);
        btnClear = (Button) findViewById(R.id.btnClear);

        btnPairedDevices.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {

                // Obter um adaptador Bluetooth
                mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
                if (mBluetoothAdapter == null) {
                    Toast.makeText(getApplicationContext(), "Bluetooth com problema", Toast.LENGTH_SHORT).show();
                }

                // Solicitação para ativar o Bluetooth
                if (!mBluetoothAdapter.isEnabled()) {
                    Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
                    startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT);
                }

                // Entre na interface de conexão do dispositivo Bluetooth
                Intent intent = new Intent();
                intent.setClass(getApplicationContext(), DevicesListActivity.class);
                startActivity(intent);

            }
        });

        if(txtIsConnected.getText().equals("Desconectado")) {
            edtReceivedMessage.setVisibility(View.GONE);
            edtSentMessage.setVisibility(View.GONE);
            edtSendMessage.setVisibility(View.GONE);
            btnSend.setVisibility(View.GONE);
        }
        // Depois de clicar no botão [Enviar], o texto na caixa de texto é
        // enviado para o dispositivo Bluetooth conectado em código ASCII.
        btnSend.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (edtSendMessage.getText().toString().isEmpty()) {
                    return;
                }
                String sendStr = edtSendMessage.getText().toString();
                char[] chars = sendStr.toCharArray();
                byte[] bytes = new byte[chars.length];
                for (int i=0; i < chars.length; i++) {
                    bytes[i] = (byte) chars[i];
                }
                edtSentMessage.append(sendStr);
                mConnectedThread.write(bytes);
                startTime = System.nanoTime();
            }
        });

        btnClear.setOnClickListener(new View.OnClickListener(){
            @Override
            public void onClick(View v) {
                edtSendMessage.setText("");
                edtSentMessage.setText("");
                edtReceivedMessage.setText("");
            }
        });

    }

    @Override
    protected void onResume() {
        super.onResume();

        //Volte para a interface principal e verifique se o dispositivo Bluetooth foi
        // conectado com sucesso.
        if (BluetoothUtils.getBluetoothSocket() == null || mConnectedThread != null) {
            txtIsConnected.setText("Desconectado");
            return;
        }

        edtReceivedMessage.setVisibility(View.VISIBLE);
        edtSentMessage.setVisibility(View.VISIBLE);
        edtSendMessage.setVisibility(View.VISIBLE);
        btnSend.setVisibility(View.VISIBLE);
        txtIsConnected.setText("Conectado");

        // Quando um dispositivo Bluetooth está conectado, os dados são
        // recebidos e exibidos na caixa de texto da área de recepção
        Handler handler = new Handler() {
            @Override
            public void handleMessage(Message msg) {
                super.handleMessage(msg);
                switch (msg.what) {
                    case ConnectedThread.MESSAGE_READ:
                        byte[] buffer = (byte[]) msg.obj;
                        int length = msg.arg1;
                        for (int i=0; i<length; i++) {
                            valoresLidos.add(buffer[i]);
//                            String number = String.valueOf(buffer[i]);
//                            for(int j=0; j<number.length(); j++) {
//                                char c = number.charAt(j);
//                                edtReceivedMessage.getText().append(c);
//                            }
                        }
                        if(valoresLidos.size() % 30 == 0){
                            endTime = System.nanoTime();
                            System.out.println("Li todos em " + (endTime-startTime)/1000000 + " ms.");
                            System.out.println(Arrays.toString(valoresLidos.toArray()));
                        }
                        break;
                }

            }
        };

        // Iniciar o envio e recebimento de dados por Bluetooth
        mConnectedThread = new ConnectedThread(BluetoothUtils.getBluetoothSocket(), handler);
        mConnectedThread.start();

    }
}