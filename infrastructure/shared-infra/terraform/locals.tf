locals {
  ssh_keys = {
    live-infra-staging = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJI+ej2JpsbxyCtScmGZWseA+TeHica1a1hGtTgrX/mi cardano@ip-172-31-26-83.eu-central-1.compute.internal"
    pablo              = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCeNj/ZQL+nynseTe42O4G5rs4WqyJKEOMcuiVBki2XT/UuoLz40Lw4b54HtwFTaUQQa3zmSJN5u/5KC8TW8nIKF/7fYChqypX3KKBSqBJe0Gul9ncTqHmzpzrwERlh5GkYSH+nr5t8cUK1pBilscKbCxh5x6irOnUmosoKJDv68WKq8WLsjpRslV5/1VztBanFFOZdD3tfIph1Yn7j1DQP4NcT1cQGoBhO0b0vwHtz6vTY4SpHnYuwB1K4dQ3k+gYJUspn03byi/8KVvcerLKfXYFKR5uvRkHihlIwjlxL2FoXIkGhtlkFVFOx76CvEv8LU5AT1ueJ34C/qP6PSD//pezXkk3e4UGeQMLOUu507FjfjHjD4luxIInzBb1KLAjzxb+2B4JTHy2uUu1dpHXarqSyR3DAPcLqUjZajZ+6mQh7zNRgkwXyZqg9p2TOdfiH9dvrqPowocGJgfjsYnd9rfdQVc10h1zk4pP4pP/YhgMVzYYc/ytCqUP41zSsrtJI592PUS9/quDGfrUcuG4t06DJgevky5AGX2og+sR4e83UpgId/DdV/m1OIvuoS4iMrzN2XmZ7IaFxH03nWQPrndDJ3j9ZHiaZ9IyW0XwthJFXcaslL5w3c0+1y8blxhC0vHT4NUsf5vcY3pFrBsMbTt1yNIGcitnLhXC1k99JbQ=="
    hernan             = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDR3qtsMDFjfMFBn+Xgic3cFLv5+wnKPTFV8ps3tlLnmJLPSVbhhXRYsn0ZDZtSbfSFyGWIEDLIBDp61DjkrO/qObv0hu9BOT54YSEUel89fTWHX2dEqUd0zEU9YvwHTVfIeuNOg3T7pcwtFSDCND/CE1o1rpYWWXshF10qrBVUuWJJxpJJF6LVVHD6xn6Yf6qR5PJ1WKJyR/+LL18FZuS4j0V0PJP1Kv1hHmlWM5v8N6IX+HQY/SdoB0e9xrOMbwFRTBxjpt2qeRVB7nskHnXEEBCm16aXi41XqdV+II1rkdY9oFPzjdNBTz7QHrf+1TIGiBIlhdC8tkbBtUPDZB/ywRtthM3o46dddxaVJnp1lqeVCDVckej4IYnRJTWYaFoG13peaIh+SXLGfLrdlWnjfzHx/4VmDfhpgi5Jmmfoel8S1n3cn4woEmbCK2aKWP1p8FCpY4QFICT5aJY3nkk0ciglbC58Q4sm3Pm3Hr3Stfe0RxZhQwosLAWX6kqr+EU= hrajchert@MacBook-Pro-de-Hernan.local"
  }
  root_ssh_keys_ks = ["pablo", "hernan"]
  root_ssh_keys    = [for k in local.root_ssh_keys_ks : local.ssh_keys[k]]
}
