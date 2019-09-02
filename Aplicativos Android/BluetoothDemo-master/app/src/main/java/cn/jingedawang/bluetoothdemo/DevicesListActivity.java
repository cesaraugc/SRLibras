package cn.jingedawang.bluetoothdemo;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.ListView;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Created by wjg on 2017/6/11.
 */

public class DevicesListActivity extends Activity {

    private ProgressBar progressbarSearchDevices;

    private BluetoothAdapter mBluetoothAdapter;
    private List<String> mDevicesArray = new ArrayList<String>();
    private DevicesListAdapter<String> devicesListAdapter;
    private List<BluetoothDevice> deviceList = new ArrayList<BluetoothDevice>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.listview_devices);

        ListView listView = (ListView) findViewById(R.id.listview_devices);
        progressbarSearchDevices = (ProgressBar) findViewById(R.id.progressbar_search_devices);
        mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();

        // Adicionar dispositivos emparelhados à lista
        Set<BluetoothDevice> pairedDevices = mBluetoothAdapter.getBondedDevices();
        if (pairedDevices.size() > 0) {
            for (BluetoothDevice device : pairedDevices) {
                mDevicesArray.add(device.getName() + "\n" + device.getAddress());
                deviceList.add(device);
            }
        }


        // Registrar um receptor de transmissão para obter resultados de pesquisa de dispositivo Bluetooth
        IntentFilter filter = new IntentFilter(BluetoothDevice.ACTION_FOUND);
        registerReceiver(mReceiver, filter); // Don't forget to unregister during onDestroy
        // Procurar por dispositivos Bluetooth
        mBluetoothAdapter.startDiscovery();
        progressbarSearchDevices.setVisibility(View.VISIBLE);

        // Definir o adaptador para o controle ListView
        devicesListAdapter = new DevicesListAdapter<String>(getApplicationContext(), mDevicesArray);
        listView.setAdapter(devicesListAdapter);

    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        unregisterReceiver(mReceiver);
    }

    // Create a BroadcastReceiver for ACTION_FOUND
    private final BroadcastReceiver mReceiver = new BroadcastReceiver() {
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();
            // When discovery finds a device
            if (BluetoothDevice.ACTION_FOUND.equals(action)) {
                // Get the BluetoothDevice object from the Intent
                BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
                deviceList.add(device);
                // Add the name and address to an array adapter to show in a ListView
                mDevicesArray.add(device.getName() + "\n" + device.getAddress());
                Toast.makeText(getApplicationContext(), device.getName() + "\n" + device.getAddress(), Toast.LENGTH_SHORT).show();
                devicesListAdapter.notifyDataSetChanged();
            }
        }
    };

    class DevicesListAdapter<T> extends BaseAdapter {

        Context context;
        List<T> list;
        private LayoutInflater inflater;
        public DevicesListAdapter(Context context, List list){
            this.context = context;
            this.list = list;
            inflater = LayoutInflater.from(context);
        }

        @Override
        public int getCount() {
            return list.size();
        }

        @Override
        public T getItem(int position) {
            return list.get(position);
        }

        @Override
        public long getItemId(int position) {
            return position;
        }

        @Override
        public View getView(final int position, View convertView, ViewGroup parent) {
            Holder holder;
            if(convertView==null){
                holder = new Holder();
                convertView = inflater.inflate(R.layout.item_listview_devices, null);
                holder.deviceName = (TextView) convertView.findViewById(R.id.item_device_name);
                convertView.setTag(holder);
            }else{
                holder = (Holder) convertView.getTag();
            }
            holder.deviceName.setText(list.get(position).toString());
            holder.deviceName.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    BluetoothDevice device = deviceList.get(position);
            BluetoothSocket socket = null;
            try {
                // O UUID correspondente ao serviço de porta serial Bluetooth. Se você estiver
                // usando outros serviços Bluetooth, precisará alterar a sequência a seguir.
                UUID MY_UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB");
                socket = device.createRfcommSocketToServiceRecord(MY_UUID);
            } catch (Exception e) {
                Log.d("log", "Falha ao obter Socket");
                Toast.makeText(getApplicationContext(), "Falha ao obter Socket", Toast.LENGTH_SHORT).show();
                return;
            }
            mBluetoothAdapter.cancelDiscovery();
            try {
                // Connect the device through the socket. This will block
                // until it succeeds or throws an exception
                socket.connect();
                Log.d("log", "Conectado");
                Toast.makeText(getApplicationContext(), "Conectado", Toast.LENGTH_SHORT).show();
                BluetoothUtils.setBluetoothSocket(socket);
                progressbarSearchDevices.setVisibility(View.INVISIBLE);

                // A conexão é bem sucedida, retorne à interface principal
                finish();
            } catch (IOException connectException) {
                // Unable to connect; close the socket and get out
                Log.d("log", "Erro ao conectar");
                try {
                    socket.close();
                } catch (IOException closeException) { }
                return;
            }


                }
            });
            return convertView;
        }

        protected class Holder{
            TextView deviceName;
        }

    }
}
