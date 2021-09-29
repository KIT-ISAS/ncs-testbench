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

package ncs_testbench.networks;

import inet.node.serum.SerumRouter6;
import libncs_omnet.util.AppTransportHost;
import inet.networklayer.configurator.ipv6.FlatNetworkConfigurator6;
import libncs_omnet.OracleCC.OracleCCCoordinator;
import inet.node.inet.StandardHost;
import libncs_omnet.NcsInstance;
import libncs_omnet.NcsHost;
import ned.DatarateChannel;


network FourHopNcs
{
    @display("bgb=937,463");

    // Tuneables
    bool useOracleCC = default(false);

    int numNcs12 = default(0);
    int numNcs13 = default(0);
    int numNcs14 = default(0);
    int numNcs23 = default(0);
    int numNcs24 = default(0);
    int numNcs34 = default(0);
    int numCross = default(0);

    double defaultLineRate @unit("bps") = default(100Mbps);
    double bottleneckLineRate @unit("bps") = default(10Mbps);
    double crossLineRate @unit("bps") = default(defaultLineRate);
    double linkRate12 @unit("bps") = default(bottleneckLineRate);
    double linkRate23 @unit("bps") = default(bottleneckLineRate);
    double linkRate34 @unit("bps") = default(bottleneckLineRate);

    int ethOverhead @unit("Byte") = default(26B);
    int pppOverhead @unit("Byte") = default(7B);
    int ipOverhead @unit("Byte") = default(40B);
    int tcpOverhead @unit("Byte") = default(20B);
    int tcpTransportOverhead @unit("Byte") = default(4B); // 4 Byte TCPTransport prefix
    int udpOverhead @unit("Byte") = default(8B);

    int mtu @unit("byte") = default(1500B);
    int crossPacketLength @unit("Byte") = default(mtu + pppOverhead);
    int crossControlPacketLength @unit("Byte") = default(400B);
    int crossUdpPayloadLength @unit("Byte") = crossPacketLength - pppOverhead - ipOverhead - udpOverhead;
    int crossTcpPayloadLength @unit("Byte") = crossPacketLength - pppOverhead - ipOverhead - tcpOverhead - tcpTransportOverhead;

    double networkSetupTime @unit("s") = default(20s);
    double ncsStartupDelay @unit("s") = default(30s);
    double ncsStartupOffset @unit("s") = default(2.001s);
    double crossStartTime @unit("s") = default(40s);

    //
    // PPP Buffer/Queue setup
    //
    **.mtu = default(mtu); // like Ethernet
    **.ppp[*].queueType = default("DropTailQueue");
    // NIC configuration
    *Host*.ppp[*].queue.frameCapacity = default(5);
    // Router configuration
    ic*.ppp[*].queue.frameCapacity = default(50);

    // NCS network startup delay
    ncs*.ncsContext.networkStartupPollInterval = default(networkSetupTime);


    // TCP/UDP setup
    **.tcp.mss = dropUnit(crossTcpPayloadLength + tcpTransportOverhead);
    **.tcp.windowScalingSupport = true;
    **.tcp.advertisedWindow = 2^10 * dropUnit(mtu);
    **.tcp.limitedTransmitEnabled = true;
    //**.tcp.sackSupport = true; # disabled because implementation is buggy

    //
    // Cross Traffic
    //
    *Host*[*].tcpTransport.datagramService = false;
    *Host*[*].transportAppType = "TrafGenApp";
    *Host*[*].app.gen.generateRaw = default(false); // only required if Network Simulation Cradle should be used

    xHost*[*].useTcp = false;
    xHost*[*].useUdp = true;
    xHost*[*].app.redir.tOpen = networkSetupTime;
    //controlHost*[*].app.gen.startTime = default(crossStartTime + uniform(0,1) * 1s); // applied below to bind variable to instance context
    xHost*[*].app.gen.stopTime = default(-1s);
    xHostB[*].app.gen.numPackets = default(0); // B hosts do not send by default!
    xHost*[*].app.gen.packetLength = default(crossUdpPayloadLength);
    xHost*[*].app.gen.sendInterval = default(uniform(1,10) * 1ms); // 100..1000Hz


    types:
        channel DefaultLinkChannel extends ned.DatarateChannel
        {
            @defaultname(defaultLinkChannel);
            datarate = default(defaultLineRate);
        }
        channel CrossLink extends ned.DatarateChannel
        {
            @defaultname(crossLink);
            datarate = default(crossLineRate);
        }
        channel Link12 extends ned.DatarateChannel
        {
            @defaultname(link12);
            datarate = default(linkRate12);
        }
        channel Link23 extends ned.DatarateChannel
        {
            @defaultname(link23);
            datarate = default(linkRate23);
        }
        channel Link34 extends ned.DatarateChannel
        {
            @defaultname(link34);
            datarate = default(linkRate34);
        }
        channel NcsActorLink extends DefaultLinkChannel
        {
            @defaultname(ncsActorLink);
        }
        channel NcsControllerLink extends DefaultLinkChannel
        {
            @defaultname(ncsControllerLink);
        }
        channel NcsSensorLink extends DefaultLinkChannel
        {
            @defaultname(ncsSensorLink);
        }

    submodules:
        ic1: SerumRouter6 {
            @display("p=258,254");
        }
        ic2: SerumRouter6 {
            @display("p=439,254");
        }
        ic3: SerumRouter6 {
            @display("p=620,254");
        }
        ic4: SerumRouter6 {
            @display("p=803,254");
        }
        ncs12[numNcs12]: NcsInstance {
            @display("p=330,164");

            ncsContext.startupDelay = default(ncsStartupDelay + index * ncsStartupOffset);
        }
        ncs13[numNcs13]: NcsInstance {
            @display("p=308,302");

            ncsContext.startupDelay = default(ncsStartupDelay + (index + numNcs12) * ncsStartupOffset);
        }
        ncs14[numNcs14]: NcsInstance {
            @display("p=219,390");

            ncsContext.startupDelay = default(ncsStartupDelay + (index + numNcs12 + numNcs13) * ncsStartupOffset);
        }
        ncs23[numNcs23]: NcsInstance {
            @display("p=509,152");

            ncsContext.startupDelay = default(ncsStartupDelay + (index + numNcs12 + numNcs13 + numNcs14) * ncsStartupOffset);
        }
        ncs24[numNcs24]: NcsInstance {
            @display("p=439,62");

            ncsContext.startupDelay = default(ncsStartupDelay + (index + numNcs12 + numNcs13 + numNcs14 + numNcs23) * ncsStartupOffset);
        }
        ncs34[numNcs34]: NcsInstance {
            @display("p=728,113");

            ncsContext.startupDelay = default(ncsStartupDelay + (index + numNcs12 + numNcs13 + numNcs14 + numNcs23 + numNcs24) * ncsStartupOffset);
        }
        xHostA[numCross]: AppTransportHost {
            @display("p=206,53");

            app.redir.connectAddress = "xHostB[$index]";

            app.gen.startTime = default(crossStartTime + uniform(0,1) * 1s);
        }
        xHostB[numCross]: AppTransportHost {
            @display("p=868,53");

            app.redir.connectAddress = "xHostA[$index]";

            app.gen.startTime = default(crossStartTime + uniform(0,1) * 1s);
        }
        configurator: FlatNetworkConfigurator6 {
            @display("p=45,92");
        }
        // OracleCC managing instance
        oracleCCCoordinator: OracleCCCoordinator if useOracleCC {
            @display("p=45,189");
        }


    connections allowunconnected:

        ic1.pppg++ <--> Link12 <--> ic2.pppg++;
        ic2.pppg++ <--> Link23 <--> ic3.pppg++;
        ic3.pppg++ <--> Link34 <--> ic4.pppg++;

        for i=0..numNcs12-1 {
            ncs12[i].gActor <--> NcsActorLink <--> ic2.pppg++;
            ncs12[i].gController <--> NcsControllerLink <--> ic1.pppg++;
            ncs12[i].gSensor <--> NcsSensorLink <--> ic1.pppg++;
        }
        for i=0..numNcs13-1 {
            ncs13[i].gActor <--> NcsActorLink <--> ic3.pppg++;
            ncs13[i].gController <--> NcsControllerLink <--> ic1.pppg++;
            ncs13[i].gSensor <--> NcsSensorLink <--> ic1.pppg++;
        }
        for i=0..numNcs14-1 {
            ncs14[i].gActor <--> NcsActorLink <--> ic4.pppg++;
            ncs14[i].gController <--> NcsControllerLink <--> ic1.pppg++;
            ncs14[i].gSensor <--> NcsSensorLink <--> ic1.pppg++;
        }
        for i=0..numNcs23-1 {
            ncs23[i].gActor <--> NcsActorLink <--> ic3.pppg++;
            ncs23[i].gController <--> NcsControllerLink <--> ic2.pppg++;
            ncs23[i].gSensor <--> NcsSensorLink <--> ic2.pppg++;
        }
        for i=0..numNcs24-1 {
            ncs24[i].gActor <--> NcsActorLink <--> ic4.pppg++;
            ncs24[i].gController <--> NcsControllerLink <--> ic2.pppg++;
            ncs24[i].gSensor <--> NcsSensorLink <--> ic2.pppg++;
        }
        for i=0..numNcs34-1 {
            ncs34[i].gActor <--> NcsActorLink <--> ic4.pppg++;
            ncs34[i].gController <--> NcsControllerLink <--> ic3.pppg++;
            ncs34[i].gSensor <--> NcsSensorLink <--> ic3.pppg++;
        }
        
        for i=0..numCross-1 {
            xHostA[i].pppg++ <--> CrossLink <--> ic1.pppg++;
            xHostB[i].pppg++ <--> CrossLink <--> ic4.pppg++;
        }

}
