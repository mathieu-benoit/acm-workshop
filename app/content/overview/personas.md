---
title: "Personas"
weight: 2
tags: ["apps-operator", "org-admin", "platform-admin"]
---
3 personas are involved:
- **Org Admin**
- **Platform Admin**
- **Apps Operator**

Here are the needs of each persona:

![Personas's needs](https://github.com/mathieu-benoit/my-images/raw/main/acm-workshop/personas-needs.png)

{{% notice info %}}
The **Developer** persona is not involved in this workshop for the reason that they should focus on the code of their apps. The **Apps Operator** persona is responsible to set up the Continuous Integration part to build and push the container images associated to any apps the **Developers** are building. With this workshop we are not covering this part, we are assuming that the container images are already built, the **Apps Operator** persona will take it from here in this workshop and will configure the Continuous Deployment part.
{{% /notice %}}

Here is what the 3 personas will accomplish throughout this workshop:

![Personas](https://github.com/mathieu-benoit/my-images/raw/main/acm-workshop/personas.png)