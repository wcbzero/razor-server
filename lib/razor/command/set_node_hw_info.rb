# -*- encoding: utf-8 -*-

class Razor::Command::SetNodeHWInfo < Razor::Command
  summary "Change the hardware info on an existing node"
  description <<-EOT
    When hardware is changed in a node, such as a network card being replaced,
    the Razor server may need to be informed so that it can correctly match
    the new hardware with the existing node definition.

    This command enables replacing the existing hardware info data with new
    data, making it possible to update the existing node record prior to
    booting the new node on the network.

    The supplied hardware info must include at least one key that is configured
    as part of the matching process; on your razor-server that is one of:
    #{Razor.config['match_nodes_on'].map{|n| " * #{n}"}.join("\n")}
  EOT

  example <<-EOT
Update `node172` with new hardware information:

    {
      "node": "node172",
      "hw_info": {
        "net0":   "78:31:c1:be:c8:00",
        "net1":   "72:00:01:f2:13:f0",
        "net2":   "72:00:01:f2:13:f1",
        "serial": "xxxxxxxxxxx",
        "asset":  "Asset-1234567890",
        "uuid":   "Not Settable"
      }
    }
  EOT

  authz  '%{node}'
  attr   'node', required: true, references: Razor::Data::Node, help: _(<<-HELP)
    The node to modify the hardware information of
  HELP

  object 'hw_info', required: true, size: 1..Float::INFINITY, help: _(<<-HELP) do
    The new hardware information for the node
  HELP
    extra_attrs /^net[0-9]+$/, type: String, help: _(<<-HELP)
      The MAC address of a network adapter associated with the node.
    HELP

    attr 'serial', type: String, help: _('The DMI serial number of the node')
    attr 'asset', type: String, help: _('The DMI asset tag of the node')
    attr 'uuid', type: String, help: _('The DMI UUID of the node')
  end

  def run(request, data)
    if (data['hw_info'].keys & Razor.config['match_nodes_on']).empty?
      msg = _('hw_info must contain at least one of the match keys: %{keys}') %
        {keys: Razor.config['match_nodes_on'].join(', ')}
      raise Razor::ValidationFailure.new(msg)
    else
      Razor::Data::Node[name: data['node']].tap do |node|
        node.hw_hash = data['hw_info']
        node.save
      end
    end
  end
end
