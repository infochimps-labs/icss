def test_icss
  return <<EOF
---
namespace: foo.bar
protocol: baz
types:

- name: place
  doc: Foo bar place
  type: record
  fields:
  - name: name
    doc: Your name.
    type: string
  - name: website
    doc: Your website.
    type: url
EOF
end
