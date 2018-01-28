//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public License
// along with this program.  If not, see http://www.gnu.org/licenses/.
// 

// Created: 2016-11-16 for project ncs-testbench

package ncs_testbench.simulations;

import inet.node.inet.Router;
import libncs_omnet.util.AppTransportHost;
import inet.applications.tcpapp.TCPGenericSrvApp;
import inet.applications.tcpapp.TCPSessionApp;
import inet.applications.tcpapp.TCPSrvHostApp;
import inet.applications.tcpapp.TelnetApp;
import inet.networklayer.configurator.ipv4.IPv4NetworkConfigurator;
import inet.node.inet.StandardHost;
import libncs_omnet.NcsManager;
import libncs_omnet.NcsInstance;
import libncs_omnet.NcsHost;
import ned.DatarateChannel;


network SimpleNcs
{
    @display("bgb=789,296");

    // Tuneables
    bool bottleneckSensor = default(true); // true: controller<->sensor is bottleneck
    bool bottleneckActor = default(!bottleneckSensor); // else controller<->actuator
    
    int defaultLineRate @unit("bps") = default(100Mbps);
    int bottleneckLineRate @unit("bps") = default(10Mbps);

    int ethOverhead @unit("Byte") = default(26B);
    int pppOverhead @unit("Byte") = default(7B);
    int ipOverhead @unit("Byte") = default(20B);
    int tcpOverhead @unit("Byte") = default((32B + 2B)); // 32 Byte TCP + 2 Byte TCPTransport
    int udpOverhead @unit("Byte") = default(8B);

    int mtu @unit("byte") = default(1500B);

    // Cross Traffic is TCP (true) or UDP (false)
    bool crossTcp = default(true);
    int crossLineRate @unit("bps") = default(defaultLineRate);
    volatile double crossFlowRate @unit("bps") = default(0.5Mbps);
    int crossPacketLength @unit("Byte") = default(mtu);
    int crossPayloadLength @unit("Byte") = crossPacketLength - pppOverhead - ipOverhead - (crossTcp ? tcpOverhead : udpOverhead);

    //
    // PPP Buffer/Queue setup
    //
    **.mtu = mtu; // like Ethernet
    **.ppp[*].queueType = "DropTailQueue";
    // NIC configuration
    *Host*.ppp[*].queue.frameCapacity = default(5);
    // Router configuration
    r*.ppp[*].queue.frameCapacity = default(50);


    //
    // TCP Cross Traffic
    //
    crossHost*.useTcp = crossTcp;
    crossHost*.useUdp = !crossTcp;
    crossHost*.tcpTransport.datagramService = true;
    crossHost*.transportAppType = "TrafGenApp";

    crossHost*.app.gen.generateRaw = true;
    crossHost*.app.gen.startTime = default(20s); // time of sending the first packet
    crossHost*.app.gen.stopTime = default(50s);  // time of finishing sending, negative values mean forever
    crossHost*.app.gen.packetLength = default(crossPayloadLength);
    // crossHost*.app.gen.numPackets = default(-1); // max number of packets to generate, -1 means forever
    crossHost*.app.gen.sendInterval = default(dropUnit(crossPacketLength) * 8 / dropUnit(crossFlowRate) *1s); // may be a random value, e.g. exponential(1)
    //crossHost*.app.redir.localPort = 1000;
    //crossHost*.app.redir.connectPort = 1000;
    //crossHost*.app.redir.tOpen = 0s;
    //crossHost*.app.redir.tClose = default(-1s);

    types:
        channel BottleneckLinkChannel extends ned.DatarateChannel
        {
            @defaultname(bottleneckLinkChannel);
            datarate = default(bottleneckLineRate);
        }
        channel DefaultLinkChannel extends ned.DatarateChannel
        {
            @defaultname(defaultLinkChannel);
            datarate = default(defaultLineRate);
        }
        channel CrossLinkChannel extends ned.DatarateChannel
        {
            @defaultname(crossLinkChannel);
            datarate = default(crossLineRate);
        }
        channel BottleneckLink extends BottleneckLinkChannel
        {
            @defaultname(bottleneckLink);
        }
        channel ActorLink extends DefaultLinkChannel
        {
            @defaultname(ActorLink);
        }
        channel ControllerLink extends DefaultLinkChannel
        {
            @defaultname(ControllerLink);
        }
        channel SensorLink extends DefaultLinkChannel
        {
            @defaultname(SensorLink);
        }
        channel CrossLinkA extends CrossLinkChannel
        {
            @defaultname(crossLinkA);
        }
        channel CrossLinkB extends CrossLinkChannel
        {
            @defaultname(crossLinkB);
        }
    submodules:
        // Responsible to set up the MATLAB part of the simulation
        NcsManager: NcsManager {
            @display("p=45,27");
        }
        r1: Router {
            @display("p=284,221");
        }
        r2: Router {
            @display("p=509,221");
        }
        // A NCS
        ncs: NcsInstance {
            @display("p=397,123");
        }
        // Configure some routes automagically
        configurator: IPv4NetworkConfigurator {
            @display("p=45,92");
        }
        // Two hosts responsible for sending/receiving cross-traffic
        crossHostA: AppTransportHost {
            @display("p=120,222");

            app.redir.connectAddress = "crossHostB";
        }
        crossHostB: AppTransportHost {
            @display("p=680,222");

            app.redir.connectAddress = "crossHostA";
        }
    connections allowunconnected:

        // Bottleneck between routers r1 and r2
        r1.pppg++ <--> BottleneckLink <--> r2.pppg++;
        
        // Each NCS has one connection for Actor, Controller an Sensor.
        // The graphical rendering looks a bit odd, but the scenario can be setup and configured easier this way
        
        // Both sensor and actor can be connected to either the same router as the Controller (r1),
        // or to the other router accross the bottleneck link (r2)
        ncs.gActor <--> ActorLink <--> r1.pppg++ if !bottleneckActor;
        ncs.gActor <--> ActorLink <--> r2.pppg++ if bottleneckActor;
        ncs.gController <--> ControllerLink <--> r1.pppg++;
        ncs.gSensor <--> SensorLink <--> r1.pppg++ if !bottleneckSensor;
        ncs.gSensor <--> SensorLink <--> r2.pppg++ if bottleneckSensor;

        // Connect cross traffic hosts to routers r1/r2 
        crossHostA.pppg++ <--> CrossLinkA <--> r1.pppg++;
        crossHostB.pppg++ <--> CrossLinkB <--> r2.pppg++;
}
